import SwiftUI

struct StandardCardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(16)
            .background(Color.surfaceWhite)
            .cornerRadius(16)
            // Subtle shadow (Level 2)
            .shadow(color: Color.black.opacity(0.06), radius: 12, x: 0, y: 4)
    }
}

extension View {
    func standardCardStyle() -> some View {
        modifier(StandardCardModifier())
    }
    
    // Standard screen background application
    func appBackground() -> some View {
        self.background(Color.cream50.ignoresSafeArea())
    }
}

// Spacing constants
enum Spacing {
    static let small: CGFloat = 8
    static let standard: CGFloat = 16
    static let large: CGFloat = 24
    static let section: CGFloat = 32
}
