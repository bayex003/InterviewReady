import SwiftUI

struct QuestionDetailView: View {
    @EnvironmentObject private var dataStore: DataStore
    let question: InterviewQuestion
    @State private var draftAnswer: String = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(question.text)
                    .font(.system(.title3, design: .rounded).bold())
                    .foregroundStyle(.white)
                VStack(alignment: .leading, spacing: 10) {
                    Text("Why they ask this")
                        .font(.headline)
                    Text(question.whyItMatters)
                        .foregroundColor(.white.opacity(0.85))
                }
                .padding()
                .background(Color.white.opacity(0.06))
                .cornerRadius(16)

                VStack(alignment: .leading, spacing: 10) {
                    Text("Suggested structure")
                        .font(.headline)
                    ForEach(question.answerStructure, id: \.self) { item in
                        HStack(alignment: .top) {
                            Circle().fill(Color.indigo).frame(width: 8, height: 8)
                            Text(item)
                        }
                    }
                }
                .padding()
                .background(Color.white.opacity(0.05))
                .cornerRadius(16)

                VStack(alignment: .leading, spacing: 10) {
                    Text("Example answers")
                        .font(.headline)
                    ForEach(question.exampleAnswers, id: \.self) { answer in
                        Text(answer)
                            .padding()
                            .background(Color.white.opacity(0.04))
                            .cornerRadius(12)
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Create my own answer")
                        .font(.headline)
                    TextEditor(text: $draftAnswer)
                        .frame(minHeight: 160)
                        .padding(8)
                        .background(Color.white.opacity(0.05))
                        .cornerRadius(12)
                    PrimaryButton(title: "Save to My Answers") {
                        let answer = UserAnswer(questionID: question.id, answerText: draftAnswer, category: question.category)
                        dataStore.addOrUpdateAnswer(answer)
                        draftAnswer = ""
                    }
                }
            }
            .padding()
        }
        .background(Color.irBackground.ignoresSafeArea())
        .navigationTitle("Question")
    }
}
