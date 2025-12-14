import SwiftUI

extension JobStage {
    var color: Color {
        switch self {
        case .saved:
            return Color.ink600 // Gray/Neutral
        case .applied:
            return Color.blue   // Standard Blue
        case .interviewing:
            return Color.sage500 // Your Brand Green
        case .offer:
            return Color.green  // Bright Success Green
        case .rejected:
            return Color.red    // Red
        }
    }
    
    var icon: String {
        switch self {
        case .saved: return "bookmark"
        case .applied: return "paperplane"
        case .interviewing: return "person.2"
        case .offer: return "party.popper"
        case .rejected: return "xmark.circle"
        }
    }
}
