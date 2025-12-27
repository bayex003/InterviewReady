import SwiftUI

struct Chip: View {
    let title: String
    var isSelected: Bool
    var action: (() -> Void)?

    init(
        title: String,
        isSelected: Bool = false,
        action: (() -> Void)? = nil
    ) {
        self.title = title
        self.isSelected = isSelected
        self.action = action
    }

    var body: some View {
        Group {
            if let action {
                Button(action: action) {
                    label
                }
                .buttonStyle(.plain)
            } else {
                label
            }
        }
    }

    private var label: some View {
        Text(title)
            .font(.subheadline)
            .fontWeight(.medium)
            .foregroundStyle(isSelected ? Color.ink900 : Color.ink600)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(isSelected ? Color.sage100 : Color.surfaceWhite)
            .overlay(
                Capsule()
                    .stroke(isSelected ? Color.sage500 : Color.ink200, lineWidth: 1)
            )
            .clipShape(Capsule())
    }
}
