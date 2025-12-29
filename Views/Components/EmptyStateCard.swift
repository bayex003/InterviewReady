import SwiftUI

struct EmptyStateCard: View {
    private let iconName: String
    private let title: String
    private let message: String
    private let ctaTitle: String?
    private let onCTA: (() -> Void)?

    // ✅ Primary initializer (new-style)
    init(
        icon: String = "sparkles",
        title: String,
        message: String = "",
        ctaTitle: String? = nil,
        onCTA: (() -> Void)? = nil
    ) {
        self.iconName = icon
        self.title = title
        self.message = message
        self.ctaTitle = ctaTitle
        self.onCTA = onCTA
    }

    // ✅ Compatibility: supports `systemImage:` label used in older code
    init(
        systemImage: String,
        title: String,
        message: String = "",
        ctaTitle: String? = nil,
        onCTA: (() -> Void)? = nil
    ) {
        self.init(icon: systemImage, title: title, message: message, ctaTitle: ctaTitle, onCTA: onCTA)
    }

    // ✅ Compatibility: supports `subtitle:` instead of `message:`
    init(
        systemImage: String,
        title: String,
        subtitle: String,
        ctaTitle: String? = nil,
        onCTA: (() -> Void)? = nil
    ) {
        self.init(icon: systemImage, title: title, message: subtitle, ctaTitle: ctaTitle, onCTA: onCTA)
    }

    // ✅ Compatibility: supports positional strings + `systemImage:`
    // e.g. EmptyStateCard("Title", "Message", "Button", systemImage: "briefcase") { ... }
    init(
        _ title: String,
        _ message: String = "",
        _ ctaTitle: String? = nil,
        systemImage: String = "sparkles",
        onCTA: (() -> Void)? = nil
    ) {
        self.init(icon: systemImage, title: title, message: message, ctaTitle: ctaTitle, onCTA: onCTA)
    }

    var body: some View {
        CardContainer(backgroundColor: Color.surfaceWhite, cornerRadius: 22, showShadow: false) {
            VStack(alignment: .center, spacing: 16) {
                ZStack {
                    Circle()
                        .fill(Color.ink100)
                        .frame(width: 64, height: 64)

                    Image(systemName: iconName)
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundStyle(Color.ink500)
                }

                Text(title)
                    .font(.headline)
                    .foregroundStyle(Color.ink900)

                if !message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Text(message)
                        .font(.subheadline)
                        .foregroundStyle(Color.ink500)
                        .multilineTextAlignment(.center)
                }

                if let ctaTitle, let onCTA {
                    PrimaryCTAButton(title: ctaTitle) {
                        onCTA()
                    }
                }
            }
            .frame(maxWidth: .infinity)
        }
        .overlay(
            RoundedRectangle(cornerRadius: 22)
                .stroke(style: StrokeStyle(lineWidth: 1, dash: [6]))
                .foregroundStyle(Color.ink200)
        )
    }
}
