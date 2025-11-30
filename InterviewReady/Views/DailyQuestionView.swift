import SwiftUI

struct DailyQuestionView: View {
    @EnvironmentObject private var dataStore: DataStore
    @StateObject private var viewModel = DailyQuestionViewModel()

    var body: some View {
        let question = dataStore.todaysQuestion()
        VStack(alignment: .leading, spacing: 16) {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Today's Question")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.7))
                    Text(question.text)
                        .font(.system(.title2, design: .rounded).weight(.semibold))
                        .foregroundStyle(.white)
                        .padding()
                        .background(Color.white.opacity(0.06))
                        .cornerRadius(18)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Why this matters")
                            .font(.headline)
                        Text(question.whyItMatters)
                            .foregroundColor(.white.opacity(0.8))
                        Divider().background(Color.white.opacity(0.1))
                        Text("Suggested structure")
                            .font(.headline)
                        ForEach(question.answerStructure, id: \.self) { item in
                            HStack(alignment: .top) {
                                Circle()
                                    .fill(Color.indigo)
                                    .frame(width: 8, height: 8)
                                Text(item)
                                    .foregroundColor(.white.opacity(0.8))
                            }
                        }
                    }
                    .padding()
                    .background(Color.white.opacity(0.05))
                    .cornerRadius(18)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Your answer")
                            .font(.headline)
                        TextEditor(text: $viewModel.answerText)
                            .frame(minHeight: 180)
                            .padding(8)
                            .background(Color.white.opacity(0.05))
                            .cornerRadius(12)
                            .foregroundColor(.white)
                        PrimaryButton(title: "Save Answer") {
                            viewModel.saveAnswer(in: dataStore)
                        }
                    }
                }
                .padding()
            }
        }
        .background(Color.irBackground.ignoresSafeArea())
        .navigationTitle("Daily Question")
        .onAppear {
            viewModel.loadExisting(from: dataStore)
        }
    }
}
