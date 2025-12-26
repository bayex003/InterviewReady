import SwiftUI
import SwiftData

struct AddQuestionView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var text: String = ""
    @State private var category: String = "General"
    @State private var tip: String = ""
    @State private var exampleAnswer: String = ""

    // Keep categories flexible; you can edit this list anytime
    private let categories = [
        "General", "Basics", "Behavioral", "Technical",
        "Leadership", "Conflict", "Challenge", "Success", "Failure"
    ]

    var body: some View {
        NavigationStack {
            Form {
                Section("Question") {
                    TextEditor(text: $text)
                        .frame(minHeight: 120)

                    Picker("Category", selection: $category) {
                        ForEach(categories, id: \.self) { c in
                            Text(c).tag(c)
                        }
                    }
                }

                Section("Tip (optional)") {
                    TextEditor(text: $tip)
                        .frame(minHeight: 100)
                }

                Section("Example answer (optional)") {
                    TextEditor(text: $exampleAnswer)
                        .frame(minHeight: 140)
                }
            }
            .navigationTitle("New Question")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveAndDismiss() }
                        .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }

    private func saveAndDismiss() {
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else { return }

        let trimmedTip = tip.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedExample = exampleAnswer.trimmingCharacters(in: .whitespacesAndNewlines)

        let newQuestion = Question(
            text: trimmedText,
            category: category,
            isCustom: true,
            tip: trimmedTip.isEmpty ? nil : trimmedTip,
            exampleAnswer: trimmedExample.isEmpty ? nil : trimmedExample
        )

        // Optional: keep timestamps consistent (your init already sets them)
        newQuestion.updatedAt = Date()

        modelContext.insert(newQuestion)
        dismiss()
    }
}
