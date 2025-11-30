import Foundation
import SwiftUI

@MainActor
final class HomeViewModel: ObservableObject {
    @Published var welcomeMessage: String = "Welcome back, ready to get interview-ready?"

    func quickStats(dataStore: DataStore) -> (answers: Int, stories: Int, achievements: Int) {
        (dataStore.userAnswers.count, dataStore.starStories.count, dataStore.achievements.count)
    }
}
