import SwiftUI

struct ScanInsertPickerView: View {
    let scannedText: String
    let availableFields: [Field]
    @Binding var situation: String
    @Binding var task: String
    @Binding var action: String
    @Binding var result: String
    @Binding var notes: String
    @Binding var manualDraft: String

    @Environment(\.dismiss) private var dismiss

    // Prevent spam taps / double inserts
    @State private var isInserting = false

    // Track what field we inserted into (so we can disable + show feedback)
    @State private var lastInsertedField: Field?

    // ✅ MUST be module-visible (NOT private) so other views can reference it
    enum Field: String, CaseIterable, Identifiable {
        case situation = "Situation"
        case task = "Task"
        case action = "Action"
        case result = "Result"
        case notes = "Notes"
        case manualDraft = "Draft"

        var id: String { rawValue }
    }

    init(
        scannedText: String,
        availableFields: [Field] = [.situation, .task, .action, .result],
        situation: Binding<String>,
        task: Binding<String>,
        action: Binding<String>,
        result: Binding<String>,
        notes: Binding<String> = .constant(""),
        manualDraft: Binding<String> = .constant("")
    ) {
        self.scannedText = scannedText
        self.availableFields = availableFields
        self._situation = situation
        self._task = task
        self._action = action
        self._result = result
        self._notes = notes
        self._manualDraft = manualDraft
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
                    ForEach(availableFields) { field in
                        insertButton(field)
                    }
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

    private func insertButton(_ field: Field) -> some View {
        Button(field.rawValue) {
            insertText(into: field)
        }
        .disabled(isScannedTextEmpty || isInserting || lastInsertedField == field)
    }

    // MARK: - Logic

    private func insertText(into targetField: Field) {
        guard let field = binding(for: targetField) else { return }
        guard !isScannedTextEmpty else { return }
        guard !isInserting else { return }

        isInserting = true
        defer { isInserting = false }

        let newText = trimmedScannedText

        // ✅ Robust duplicate detection: normalise both sides (whitespace/newlines)
        let existing = normalised(field.wrappedValue)
        let incoming = normalised(newText)

        if !incoming.isEmpty && existing.contains(incoming) {
            UINotificationFeedbackGenerator().notificationOccurred(.warning)
            lastInsertedField = targetField
            return
        }

        if field.wrappedValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            field.wrappedValue = newText
        } else {
            field.wrappedValue += "\n\n" + newText
        }

        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        lastInsertedField = targetField
    }

    private func binding(for field: Field) -> Binding<String>? {
        switch field {
        case .situation: return $situation
        case .task: return $task
        case .action: return $action
        case .result: return $result
        case .notes: return $notes
        case .manualDraft: return $manualDraft
        }
    }

    /// Collapses multiple spaces/newlines so OCR formatting differences don’t bypass duplicate detection.
    private func normalised(_ text: String) -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let components = trimmed.components(separatedBy: .whitespacesAndNewlines)
        let compact = components.filter { !$0.isEmpty }.joined(separator: " ")
        return compact.lowercased()
    }
}

