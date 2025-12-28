import SwiftUI

enum AppTab: String, CaseIterable, Identifiable {
    case home
    case jobs
    case stories
    case practice
    case settings

    var id: String { rawValue }

    var title: String {
        switch self {
        case .home: return "Home"
        case .jobs: return "Jobs"
        case .stories: return "Stories"
        case .practice: return "Practice"
        case .settings: return "Settings"
        }
    }

    var systemImage: String {
        switch self {
        case .home: return "house"
        case .jobs: return "briefcase"
        case .stories: return "book.closed"
        case .practice: return "bubble.left.and.bubble.right"
        case .settings: return "gearshape"
        }
    }
}
