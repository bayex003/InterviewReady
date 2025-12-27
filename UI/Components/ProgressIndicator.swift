import SwiftUI

struct ProgressIndicator: View {
    enum Style {
        case dots
        case bars
    }

    let count: Int
    let currentIndex: Int
    var style: Style = .dots

    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<max(count, 0), id: \.self) { index in
                indicatorItem(isActive: index == currentIndex)
            }
        }
        .accessibilityLabel("Progress")
        .accessibilityValue("Step \(currentIndex + 1) of \(count)")
    }

    @ViewBuilder
    private func indicatorItem(isActive: Bool) -> some View {
        switch style {
        case .dots:
            Circle()
                .fill(isActive ? Color.sage500 : Color.ink200)
                .frame(width: 8, height: 8)
        case .bars:
            Capsule()
                .fill(isActive ? Color.sage500 : Color.ink200)
                .frame(width: isActive ? 24 : 12, height: 6)
        }
    }
}
