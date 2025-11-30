import SwiftUI

@main
struct InterviewReadyApp: App {
    @StateObject private var dataStore = DataStore()
    @StateObject private var proManager = ProAccessManager()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(dataStore)
                .environmentObject(proManager)
        }
    }
}

struct RootView: View {
    @EnvironmentObject private var proManager: ProAccessManager

    var body: some View {
        TabView {
            NavigationStack {
                HomeView()
            }
            .tabItem {
                Label("Home", systemImage: "house.fill")
            }

            NavigationStack {
                DailyQuestionView()
            }
            .tabItem {
                Label("Daily", systemImage: "sun.max.fill")
            }

            NavigationStack {
                MyAnswersView()
            }
            .tabItem {
                Label("Answers", systemImage: "text.bubble.fill")
            }

            NavigationStack {
                SettingsView()
            }
            .tabItem {
                Label("Settings", systemImage: "gearshape.fill")
            }
        }
        .accentColor(.indigo)
        .preferredColorScheme(.dark)
        .environment(\._isProUnlocked, proManager.isProUnlocked)
    }
}

private struct ProUnlockedKey: EnvironmentKey {
    static let defaultValue: Bool = false
}

extension EnvironmentValues {
    var _isProUnlocked: Bool {
        get { self[ProUnlockedKey.self] }
        set { self[ProUnlockedKey.self] = newValue }
    }
}
