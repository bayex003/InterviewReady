import SwiftUI

struct FloatingTabBar: View {
    @Binding var selectedTab: AppTab

    private func tabTitle(_ tab: AppTab) -> String {
        switch tab {
        case .home: return "Home"
        case .jobs: return "Jobs"
        case .questions: return "Questions"
        case .stories: return "Stories"
        }
    }

    private func pillTitle(_ tab: AppTab) -> String {
        switch tab {
        case .stories: return "Stories"
        default: return tabTitle(tab)
        }
    }

    private func tabIcon(_ tab: AppTab) -> String {
        switch tab {
        case .home: return "house.fill"
        case .jobs: return "briefcase.fill"
        case .questions: return "bubble.left.and.bubble.right.fill"
        case .stories: return "book.closed.fill"
        }
    }

    var body: some View {
        HStack(spacing: 0) {
            ForEach(AppTab.allCases, id: \.self) { tab in
                tabButton(tab)
            }
        }
        .padding(.horizontal, 8)
        .background(Color.surfaceWhite)
        .clipShape(Capsule())
        .shadow(color: Color.black.opacity(0.12), radius: 20, x: 0, y: 8)
        .padding(.horizontal, 32)
        .padding(.bottom, 16)
    }

    @ViewBuilder
    private func tabButton(_ tab: AppTab) -> some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selectedTab = tab
            }
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        } label: {
            VStack(spacing: 4) {
                Image(systemName: tabIcon(tab))
                    .font(.system(size: 22))
                    .symbolVariant(selectedTab == tab ? .fill : .none)
                    .scaleEffect(selectedTab == tab ? 1.08 : 1.0)

                if selectedTab == tab {
                    Text(pillTitle(tab))
                        .font(.caption2)
                        .fontWeight(.bold)
                        .lineLimit(1)
                        .fixedSize()
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .foregroundColor(selectedTab == tab ? Color.sage500 : Color.ink400)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(tabTitle(tab)))
    }
}
