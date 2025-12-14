import SwiftUI

struct FloatingTabBar: View {
    @Binding var selectedTab: AppTab

    private struct TabItem: Identifiable {
        let id = UUID()
        let tab: AppTab
    }

    private let items: [TabItem] = AppTab.allCases.map { TabItem(tab: $0) }

    var body: some View {
        HStack(spacing: 24) {
            ForEach(items) { item in
                Button {
                    withAnimation(.spring(response: 0.25, dampingFraction: 0.9)) {
                        selectedTab = item.tab
                    }
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: item.tab.icon)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(selectedTab == item.tab ? Color.sage500 : Color.ink500)
                        Text(item.tab.rawValue)
                            .font(.caption2)
                            .foregroundStyle(selectedTab == item.tab ? Color.sage500 : Color.ink500)
                    }
                    .padding(.vertical, 10)
                    .frame(maxWidth: .infinity)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(item.tab.rawValue)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.surfaceWhite)
                .shadow(color: Color.black.opacity(0.08), radius: 12, y: 4)
        )
        .padding(.horizontal, 16)
        .padding(.bottom, 20)
    }
}
