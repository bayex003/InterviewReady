import SwiftUI

// MARK: - CardContainer

struct CardContainer<Content: View>: View {
    var backgroundColor: Color = Color.surfaceWhite
    var cornerRadius: CGFloat = 22
    var showShadow: Bool = true
    var padding: CGFloat = 16

    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(backgroundColor)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(Color.ink200.opacity(0.8), lineWidth: 1)
            )
            .shadow(
                color: showShadow ? Color.black.opacity(0.06) : .clear,
                radius: showShadow ? 14 : 0,
                x: 0,
                y: showShadow ? 8 : 0
            )
    }
}

// MARK: - Chip

struct Chip: View {
    let title: String
    var isSelected: Bool = false
    var action: (() -> Void)? = nil

    var body: some View {
        Group {
            if let action {
                Button(action: action) { chipBody }
                    .buttonStyle(.plain)
            } else {
                chipBody
            }
        }
    }

    private var chipBody: some View {
        Text(title)
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .foregroundStyle(isSelected ? Color.sage500 : Color.ink600)
            .background(
                Capsule()
                    .fill(isSelected ? Color.sage100 : Color.ink100)
            )
            .overlay(
                Capsule()
                    .stroke(isSelected ? Color.sage500.opacity(0.25) : Color.ink200, lineWidth: 1)
            )
    }
}

// MARK: - PrimaryCTAButton

struct PrimaryCTAButton: View {
    private let title: String
    private let systemImage: String?
    private let action: () -> Void

    init(_ title: String, systemImage: String? = nil, action: @escaping () -> Void) {
        self.title = title
        self.systemImage = systemImage
        self.action = action
    }

    init(title: String, systemImage: String? = nil, action: @escaping () -> Void) {
        self.title = title
        self.systemImage = systemImage
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Spacer(minLength: 0)

                if let systemImage {
                    Image(systemName: systemImage)
                        .font(.subheadline.weight(.semibold))
                }

                Text(title)
                    .font(.subheadline.weight(.semibold))

                Spacer(minLength: 0)
            }
            .foregroundStyle(Color.surfaceWhite)
            .padding(.vertical, 14)
            .padding(.horizontal, 16)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.sage500)
            )
        }
        .buttonStyle(.plain)
    }
}
