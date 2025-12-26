import SwiftUI
import SwiftData

struct AddQuestionView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var questionText = ""
    @State private var selectedCategory = "General"
    @State private var tipText = ""
    @State private var exampleAnswerText = ""

    private let categories = ["General", "Basics", "Behavioral", "Technical", "Strengths", "Weaknesses"]

    private var isSaveDisabled: Bool {
        questionText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Question") {
                    TextEditor(text: $questionText)
                        .frame(minHeight: 120)
                        .scrollContentBackground(.hidden)
                }

                Section("Category") {
                    Picker("Category", selection: $selectedCategory) {
                        ForEach(categories, id: \.self) { category in
                            Text(category).tag(category)
                        }
                    }
                }

                Section("Tip") {
                    TextEditor(text: $tipText)
                        .frame(minHeight: 120)
                        .scrollContentBackground(.hidden)
                }

                Section("Example Answer") {
                    TextEditor(text: $exampleAnswerText)
                        .frame(minHeight: 140)
                        .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle("Add Question")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveQuestion() }
                        .disabled(isSaveDisabled)
                }
            }
            .tapToDismissKeyboard()
        }
    }

    private func saveQuestion() {
        let trimmedQuestion = questionText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuestion.isEmpty else { return }

        let tip = tipText.trimmingCharacters(in: .whitespacesAndNewlines)
        let example = exampleAnswerText.trimmingCharacters(in: .whitespacesAndNewlines)

        let question = Question(
            text: trimmedQuestion,
            category: selectedCategory,
            isCustom: true,
            tip: tip.isEmpty ? nil : tip,
            exampleAnswer: example.isEmpty ? nil : example
        )

        modelContext.insert(question)
        dismiss()
    }
}
