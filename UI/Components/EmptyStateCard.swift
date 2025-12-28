import SwiftUI

struct EmptyStateCard: View {
    let systemImage: String
    let title: String
    let subtitle: String
    let ctaTitle: String
    let action: () -> Void
    var iconBackground: Color = Color.sage100.opacity(0.8)
    var iconForeground: Color = Color.sage500

    var body: some View {
        CardContainer(backgroundColor: Color.surfaceWhite, cornerRadius: 24, showShadow: false) {
            VStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(iconBackground)
                        .frame(width: 56, height: 56)

                    Image(systemName: systemImage)
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(iconForeground)
                }

                Text(title)
                    .font(.headline)
                    .foregroundStyle(Color.ink900)

                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(Color.ink600)
                    .multilineTextAlignment(.center)

                PrimaryCTAButton(ctaTitle) {
                    action()
                }
                .frame(maxWidth: 260)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
        }
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(style: StrokeStyle(lineWidth: 1, dash: [6]))
                .foregroundStyle(Color.ink200)
        )
    }
}
