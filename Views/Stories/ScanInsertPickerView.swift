import SwiftUI

struct ScanInsertPickerView: View {
    let scannedText: String
    @Binding var situation: String
    @Binding var task: String
    @Binding var action: String
    @Binding var result: String

    @Environment(\.dismiss) private var dismiss

    // Prevent spam taps / double inserts
    @State private var isInserting = false

    // Track what field we inserted into (so we can disable + show feedback)
    @State private var lastInsertedField: Field?

    enum Field: String {
        case situation = "Situation"
        case task = "Task"
        case action = "Action"
        case result = "Result"
    }

    private var trimmedScannedText: String {
        scannedText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var isScannedTextEmpty: Bool {
        trimmedScannedText.isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Scanned Text") {
                    Text(isScannedTextEmpty ? "(No scanned text)" : scannedText)
                        .foregroundColor(isScannedTextEmpty ? .secondary : .primary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                if let lastInsertedField {
                    Section {
                        HStack(spacing: 10) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(Color.sage500)
                            Text("Inserted into \(lastInsertedField.rawValue)")
                                .foregroundStyle(Color.ink900)
                                .font(.subheadline)
                            Spacer()
                        }
                        .padding(.vertical, 4)
                    }
                }

                Section("Insert Into") {
                    insertButton(.situation, binding: $situation)
                    insertButton(.task, binding: $task)
                    insertButton(.action, binding: $action)
                    insertButton(.result, binding: $result)
                }
            }
            .navigationTitle("Insert Scanned Text")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    // MARK: - UI

    private func insertButton(_ field: Field, binding: Binding<String>) -> some View {
        Button(field.rawValue) {
            insertText(into: binding, field: field)
        }
        .disabled(isScannedTextEmpty || isInserting || lastInsertedField == field)
    }

    // MARK: - Logic

    private func insertText(into field: Binding<String>, field targetField: Field) {
        guard !isScannedTextEmpty else { return }
        guard !isInserting else { return }

        isInserting = true
        defer { isInserting = false }

        let newText = trimmedScannedText

        // ✅ Robust duplicate detection: normalise both sides (whitespace/newlines)
        let existing = normalised(field.wrappedValue)
        let incoming = normalised(newText)

        // If the exact OCR block already exists (even with whitespace differences), do nothing.
        if !incoming.isEmpty && existing.contains(incoming) {
            UINotificationFeedbackGenerator().notificationOccurred(.warning)
            lastInsertedField = targetField
            return
        }

        if field.wrappedValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            field.wrappedValue = newText
        } else {
            // Append with spacing once
            field.wrappedValue += "\n\n" + newText
        }

        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        lastInsertedField = targetField
    }

    /// Collapses multiple spaces/newlines so OCR formatting differences don’t bypass duplicate detection.
    private func normalised(_ text: String) -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)

        // Replace all whitespace runs (spaces/newlines/tabs) with a single space
        let components = trimmed.components(separatedBy: .whitespacesAndNewlines)
        let compact = components.filter { !$0.isEmpty }.joined(separator: " ")

        return compact.lowercased()
    }
}

