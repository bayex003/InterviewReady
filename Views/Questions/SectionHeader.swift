import SwiftUI

struct SectionHeader: View {
    let title: String
    let actionTitle: String
    let action: () -> Void

    init(title: String, actionTitle: String, action: @escaping () -> Void) {
        self.title = title
        self.actionTitle = actionTitle
        self.action = action
    }

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .font(.headline)
                .foregroundStyle(Color.ink900)

            Spacer()

            Button(actionTitle, action: action)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.sage500)
                .padding(.horizontal, 4)
                .padding(.vertical, 4)
                .buttonStyle(.plain)
                .accessibilityLabel("Section action: \(actionTitle)")
        }
    }
}

#Preview("SectionHeader") {
    VStack(spacing: 16) {
        SectionHeader(title: "Title", actionTitle: "Select") { }
        SectionHeader(title: "", actionTitle: "Done") { }
    }
    .padding()
}
