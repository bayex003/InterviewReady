import SwiftUI

struct MyAnswersView: View {
    @EnvironmentObject private var dataStore: DataStore
    @StateObject private var viewModel = AnswersViewModel()

    var body: some View {
        VStack {
            Picker("Filter", selection: $viewModel.selectedFilter) {
                ForEach(AnswersViewModel.Filter.allCases) { filter in
                    Text(filter.rawValue).tag(filter)
                }
            }
            .pickerStyle(.segmented)
            .padding()

            List {
                ForEach(viewModel.filteredAnswers(from: dataStore)) { answer in
                    NavigationLink(destination: AnswerDetailView(answer: binding(for: answer))) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(questionTitle(for: answer))
                                .font(.headline)
                            Text(answer.category.rawValue)
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("Updated \(answer.updatedAt.formatted(date: .abbreviated, time: .shortened))")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
        }
        .background(Color.irBackground.ignoresSafeArea())
        .navigationTitle("My Answers")
    }

    private func binding(for answer: UserAnswer) -> Binding<UserAnswer> {
        guard let index = dataStore.userAnswers.firstIndex(where: { $0.id == answer.id }) else {
            fatalError("Answer not found")
        }
        return $dataStore.userAnswers[index]
    }

    private func questionTitle(for answer: UserAnswer) -> String {
        if let id = answer.questionID, let question = dataStore.questionLibrary.first(where: { $0.id == id }) {
            return question.text
        }
        return answer.customQuestionText ?? "Custom question"
    }
}
