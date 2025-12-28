import SwiftUI

struct RootContentView: View {
    @State private var selectedTab: AppTab = .home

    @StateObject private var router = AppRouter()
    @StateObject private var attemptsStore = AttemptsStore()
    @StateObject private var jobsStore = JobsStore()

    init() {
        // ✅ Use native tab bar (NOT hidden)
        // ✅ Optional: make tab bar background consistent
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(Color.surfaceWhite)

        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }

    var body: some View {
        TabView(selection: $selectedTab) {

            NavigationStack {
                HomeView(selectedTab: $selectedTab)
            }
            .tag(AppTab.home)
            .tabItem { Label(AppTab.home.title, systemImage: AppTab.home.systemImage) }

            NavigationStack {
                JobsListView()
            }
            .tag(AppTab.jobs)
            .tabItem { Label(AppTab.jobs.title, systemImage: AppTab.jobs.systemImage) }

            NavigationStack {
                StoryBankView()
            }
            .tag(AppTab.stories)
            .tabItem { Label(AppTab.stories.title, systemImage: AppTab.stories.systemImage) }

            NavigationStack {
                QuestionsListView()
            }
            .tag(AppTab.practice)
            .tabItem { Label(AppTab.practice.title, systemImage: AppTab.practice.systemImage) }

            NavigationStack {
                SettingsView()
            }
            .tag(AppTab.settings)
            .tabItem { Label(AppTab.settings.title, systemImage: AppTab.settings.systemImage) }
        }
        // ✅ Fix the “blue” selection — now it matches your design tokens
        .tint(Color.sage500)

        // ✅ Shared state
        .environmentObject(router)
        .environmentObject(attemptsStore)
        .environmentObject(jobsStore)
    }
}
