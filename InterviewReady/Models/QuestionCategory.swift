import Foundation

enum QuestionCategory: String, Codable, CaseIterable, Identifiable {
    case aboutYou = "About You"
    case behavioural = "Behavioural"
    case strengthsWeaknesses = "Strengths & Weaknesses"
    case motivation = "Motivation & Culture Fit"
    case pressure = "Pressure & Problem Solving"
    case teamwork = "Teamwork & Collaboration"
    case leadership = "Leadership"

    var id: String { rawValue }

    var iconName: String {
        switch self {
        case .aboutYou: return "person.fill"
        case .behavioural: return "sparkles"
        case .strengthsWeaknesses: return "heart.text.square"
        case .motivation: return "flame.fill"
        case .pressure: return "bolt.fill"
        case .teamwork: return "person.3.fill"
        case .leadership: return "crown.fill"
        }
    }
}
