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
                    insertText()
                    dismiss()
                }
                .buttonStyle(.borderedProminent)

                Spacer()
            }
            .padding()
            .navigationTitle("Add scanned text to")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func insertText() {
        let trimmed = scannedText.trimmingCharacters(in: .whitespacesAndNewlines)
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
        if existing.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return newText
        }
        return existing + "\n\n" + newText
    }
}
