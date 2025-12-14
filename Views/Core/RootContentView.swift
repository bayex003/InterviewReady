import SwiftUI

// GLOBAL DEFINITION
enum AppTab: String, CaseIterable {
    case home = "Home"
    case jobs = "Jobs"
    case questions = "Questions"
    case stories = "Career Moments"

    var icon: String {
        switch self {
        case .home: return "house.fill"
        case .jobs: return "briefcase.fill"
        case .questions: return "bubble.left.and.bubble.right.fill"
        case .stories: return "book.closed.fill"
        }
    }
}

struct RootContentView: View {
    @State private var selectedTab: AppTab = .home
    @StateObject private var router = AppRouter()

    init() {
        UITabBar.appearance().isHidden = true
    }

    var body: some View {
        ZStack {
            AppBackgroundView()

            TabView(selection: $selectedTab) {
                HomeView(selectedTab: $selectedTab)
                    .tag(AppTab.home)

                JobsListView()
                    .tag(AppTab.jobs)

                QuestionsListView()
                    .tag(AppTab.questions)

                StoriesListView()
                    .tag(AppTab.stories)
            }
            .safeAreaInset(edge: .bottom) {
                if !router.isTabBarHidden {
                    FloatingTabBar(selectedTab: $selectedTab)
                }
            }
            .ignoresSafeArea(.keyboard)
            .environmentObject(router)
        }
    }
}
