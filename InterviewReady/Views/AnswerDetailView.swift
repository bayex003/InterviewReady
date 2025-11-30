import SwiftUI

struct AnswerDetailView: View {
    @EnvironmentObject private var dataStore: DataStore
    @Binding var answer: UserAnswer
    @State private var editedText: String = ""

    var body: some View {
        Form {
            Section(header: Text("Question")) {
                Text(questionTitle())
            }

            Section(header: Text("Your Answer")) {
                TextEditor(text: $editedText)
                    .frame(minHeight: 200)
            }

            Section {
                Toggle("Favourite", isOn: Binding(
                    get: { answer.isFavourite },
                    set: { newValue in
                        answer.isFavourite = newValue
                        answer.updatedAt = Date()
                        dataStore.addOrUpdateAnswer(answer)
                    }
                ))
            }
        }
        .navigationTitle("Answer")
        .onAppear {
            editedText = answer.answerText
        }
        .onDisappear {
            save()
        }
    }

    private func questionTitle() -> String {
        if let id = answer.questionID, let question = dataStore.questionLibrary.first(where: { $0.id == id }) {
            return question.text
        }
        return answer.customQuestionText ?? "Custom question"
    }

    private func save() {
        answer.answerText = editedText
        answer.updatedAt = Date()
        dataStore.addOrUpdateAnswer(answer)
    }
}
