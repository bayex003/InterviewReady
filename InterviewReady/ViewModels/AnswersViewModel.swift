import Foundation

@MainActor
final class AnswersViewModel: ObservableObject {
    enum Filter: String, CaseIterable, Identifiable {
        case all = "All"
        case favourites = "Favourites"
        case aboutYou = "About You"
        case behavioural = "Behavioural"
        case strengths = "Strengths"
        case motivation = "Motivation"
        case pressure = "Pressure"
        case teamwork = "Teamwork"
        case leadership = "Leadership"

        var id: String { rawValue }

        func matches(answer: UserAnswer) -> Bool {
            switch self {
            case .all: return true
            case .favourites: return answer.isFavourite
            case .aboutYou: return answer.category == .aboutYou
            case .behavioural: return answer.category == .behavioural
            case .strengths: return answer.category == .strengthsWeaknesses
            case .motivation: return answer.category == .motivation
            case .pressure: return answer.category == .pressure
            case .teamwork: return answer.category == .teamwork
            case .leadership: return answer.category == .leadership
            }
        }
    }

    @Published var selectedFilter: Filter = .all

    func filteredAnswers(from dataStore: DataStore) -> [UserAnswer] {
        dataStore.userAnswers.filter { selectedFilter.matches(answer: $0) }
            .sorted { $0.updatedAt > $1.updatedAt }
    }
}
