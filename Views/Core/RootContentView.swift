import SwiftUI

// Lightweight tab identifier used by RootContentView's TabView
enum AppTab: Hashable, CaseIterable, Identifiable {
    case home
    case jobs
    case stories
    case practice

    var id: Self { self }
}

// Preference key to communicate whether the floating tab bar should be hidden
private struct FloatingTabBarHiddenPreferenceKey: PreferenceKey {
    static var defaultValue: Bool = false

    static func reduce(value: inout Bool, nextValue: () -> Bool) {
        // ✅ Hide if ANY child requests hiding
        value = value || nextValue()
    }
}

// Convenience modifier to set the preference from child views
extension View {
    func floatingTabBarHidden(_ hidden: Bool = true) -> some View {
        preference(key: FloatingTabBarHiddenPreferenceKey.self, value: hidden)
    }
}

struct RootContentView: View {
    @State private var selectedTab: AppTab = .home
    @StateObject private var router = AppRouter()

    @State private var isTabBarHidden: Bool = false

    init() {
        UITabBar.appearance().isHidden = true
    }

    var body: some View {
        ZStack {
            AppBackgroundView()

            TabView(selection: $selectedTab) {
                NavigationStack {
                    HomeView(selectedTab: $selectedTab)
                }
                .tag(AppTab.home)

                NavigationStack {
                    JobsListView()
                }
                .tag(AppTab.jobs)

                NavigationStack {
                    StoryBankView()
                }
                .tag(AppTab.stories)

                NavigationStack {
                    QuestionsListView()
                }
                .tag(AppTab.practice)
            }
            .onPreferenceChange(FloatingTabBarHiddenPreferenceKey.self) { hidden in
                withAnimation(.easeInOut(duration: 0.2)) {
                    isTabBarHidden = hidden
                }
            }
            .safeAreaInset(edge: .bottom) {
                if !isTabBarHidden {
                    FloatingTabBar(selectedTab: $selectedTab)
                }
            }
            .ignoresSafeArea(.keyboard)
            .environmentObject(router)
        }
    }
}
