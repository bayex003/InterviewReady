import Foundation

@MainActor
final class AchievementsViewModel: ObservableObject {
    @Published var draft = Achievement(title: "", description: "", impact: nil)

    func load(_ achievement: Achievement) {
        draft = achievement
    }

    func save(using dataStore: DataStore) {
        dataStore.addAchievement(draft)
        draft = Achievement(title: "", description: "", impact: nil)
    }
}
