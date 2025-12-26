// Manual test checklist:
// - Scan -> OCR -> insert -> field updates once only
// - Tapping Insert repeatedly doesn’t duplicate
// - Empty/garbage OCR output disables Insert
// - While processing, Scan Notes can’t be triggered again
// - Simulator shows friendly message, no crash
import SwiftUI

struct ScanInsertPickerView: View {
    enum TargetField: String, CaseIterable, Identifiable {
        case situation = "Situation"
        case task = "Task"
        case action = "Action"
        case result = "Result"

        var id: String { rawValue }
    }

    let scannedText: String
    @Binding var situation: String
    @Binding var task: String
    @Binding var action: String
    @Binding var result: String

    @Environment(\.dismiss) private var dismiss
    @State private var selectedField: TargetField = .situation
    @State private var hasInserted = false

    private var cleanedText: String {
        OCRService.cleanText(scannedText)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Text("Add scanned text to")
                    .font(.headline)

                Picker("Add scanned text to", selection: $selectedField) {
                    ForEach(TargetField.allCases) { field in
                        Text(field.rawValue).tag(field)
                    }
                }
                .pickerStyle(.segmented)

                Button("Insert") {
                    guard !hasInserted else { return }
                    insertText()
                    hasInserted = true
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .disabled(cleanedText.isEmpty || hasInserted)

                Spacer()
            }
            .padding()
            .navigationTitle("Add scanned text to")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func insertText() {
        let trimmed = cleanedText
        guard !trimmed.isEmpty else { return }

        switch selectedField {
        case .situation:
            situation = insert(trimmed, into: situation)
        case .task:
            task = insert(trimmed, into: task)
        case .action:
            action = insert(trimmed, into: action)
        case .result:
            result = insert(trimmed, into: result)
        }
    }

    private func insert(_ newText: String, into existing: String) -> String {
        let existingTrimmed = existing.trimmingCharacters(in: .whitespacesAndNewlines)
        if existingTrimmed.isEmpty {
            return newText
        }
        return existingTrimmed + "\n\n" + newText
    }
}
