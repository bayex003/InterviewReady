import SwiftUI

struct CardContainer<Content: View>: View {
    private let backgroundColor: Color
    private let cornerRadius: CGFloat
    private let showShadow: Bool
    private let content: Content

    init(
        backgroundColor: Color = .surfaceWhite,
        cornerRadius: CGFloat = 16,
        showShadow: Bool = true,
        @ViewBuilder content: () -> Content
    ) {
        self.backgroundColor = backgroundColor
        self.cornerRadius = cornerRadius
        self.showShadow = showShadow
        self.content = content()
    }

    var body: some View {
        content
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(backgroundColor)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(Color.ink200, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .shadow(
                color: Color.black.opacity(showShadow ? 0.05 : 0),
                radius: showShadow ? 10 : 0,
                y: showShadow ? 4 : 0
            )
    }
}
