import SwiftUI

/// Reusable section header used across the app.
/// Supports BOTH:
/// - SectionHeader(title: "Title")
/// - SectionHeader(title: "Title", actionTitle: "View All") { ... }
struct SectionHeader: View {
    let title: String
    let actionTitle: String?
    let action: (() -> Void)?

    init(title: String, actionTitle: String? = nil, action: (() -> Void)? = nil) {
        self.title = title
        self.actionTitle = actionTitle
        self.action = action
    }

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .font(.title3.weight(.bold))
                .foregroundStyle(Color.ink900)

            Spacer()

            if let actionTitle,
               !actionTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
               let action {
                Button(actionTitle, action: action)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.sage500)
                    .buttonStyle(.plain)
            }
        }
        .accessibilityElement(children: .combine)
    }
}
