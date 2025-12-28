import SwiftUI

struct CardContainer<Content: View>: View {
    var backgroundColor: Color
    var cornerRadius: CGFloat
    var showShadow: Bool
    @ViewBuilder var content: () -> Content

    init(
        backgroundColor: Color = Color.black.opacity(0.08),
        cornerRadius: CGFloat = 18,
        showShadow: Bool = true,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.backgroundColor = backgroundColor
        self.cornerRadius = cornerRadius
        self.showShadow = showShadow
        self.content = content
    }

    var body: some View {
        content()
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(backgroundColor)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(Color.white.opacity(0.06), lineWidth: 1)
            )
            .shadow(color: .black.opacity(showShadow ? 0.15 : 0), radius: showShadow ? 10 : 0, x: 0, y: showShadow ? 6 : 0)
    }
}
