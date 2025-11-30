import SwiftUI

extension Color {
    static let irBackground = Color(red: 13/255, green: 26/255, blue: 45/255)
    static let irSurface = Color(red: 249/255, green: 250/255, blue: 251/255)
    static let irBorder = Color(red: 229/255, green: 231/255, blue: 235/255)
    static let irMint = Color(red: 16/255, green: 185/255, blue: 129/255)
}

struct GlassBackground: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(
                LinearGradient(colors: [Color.white.opacity(0.08), Color.white.opacity(0.02)], startPoint: .topLeading, endPoint: .bottomTrailing)
                    .blur(radius: 4)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            )
    }
}

extension View {
    func glassCard() -> some View {
        modifier(GlassBackground())
    }
}
