import Foundation

@MainActor
final class DailyQuestionViewModel: ObservableObject {
    @Published var answerText: String = ""

    func loadExisting(from dataStore: DataStore) {
        if let existing = dataStore.answerForToday() {
            answerText = existing.answerText
        }
    }

    func saveAnswer(in dataStore: DataStore) {
        dataStore.saveDailyAnswer(text: answerText)
    }
}
