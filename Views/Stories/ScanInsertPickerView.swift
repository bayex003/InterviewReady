import SwiftUI

struct ScanInsertPickerView: View {
    let scannedText: String
    @Binding var situation: String
    @Binding var task: String
    @Binding var action: String
    @Binding var result: String
    
    @Environment(\.dismiss) private var dismiss
    
    private var isScannedTextEmpty: Bool {
        scannedText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    private func insertText(into field: Binding<String>) {
        let trimmedScannedText = scannedText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedScannedText.isEmpty else { return }
        if field.wrappedValue.contains(trimmedScannedText) {
            return
        }
        if field.wrappedValue.isEmpty {
            field.wrappedValue = trimmedScannedText
        } else {
            field.wrappedValue += "\n\n" + trimmedScannedText
        }
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Scanned Text") {
                    Text(scannedText.isEmpty ? "(No scanned text)" : scannedText)
                        .foregroundColor(scannedText.isEmpty ? .secondary : .primary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                Section("Insert Into") {
                    Button("Situation") {
                        insertText(into: $situation)
                    }
                    .disabled(isScannedTextEmpty)
                    
                    Button("Task") {
                        insertText(into: $task)
                    }
                    .disabled(isScannedTextEmpty)
                    
                    Button("Action") {
                        insertText(into: $action)
                    }
                    .disabled(isScannedTextEmpty)
                    
                    Button("Result") {
                        insertText(into: $result)
                    }
                    .disabled(isScannedTextEmpty)
                }
            }
            .navigationTitle("Insert Scanned Text")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}
