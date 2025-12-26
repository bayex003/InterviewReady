// Testing Checklist:
// - Manual: open question, type something, go back → attempt added
// - Manual: open question, do nothing, go back → no attempt
// - Drill: stop recording on a question → drill attempt added
// - Attempt history: Pro user sees list; free user sees locked message + paywall opens
// - App compiles and runs

import SwiftUI
import SwiftData

@main
struct InterviewReadyApp: App {
    // Onboarding State
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false

    @StateObject private var purchaseManager = PurchaseManager()

    // Container is created after first frame to avoid long blank launch
    @State private var container: ModelContainer?
    @State private var containerLoadError: String?

    // Fade transition into the real app
    @State private var isAppReady = false

    var body: some Scene {
        WindowGroup {
            ZStack {
                if let container {
                    // THE REAL APP
                    Group {
                        if hasSeenOnboarding {
                            RootContentView()
                        } else {
                            OnboardingView(isOnboardingComplete: $hasSeenOnboarding)
                        }
                    }
                    .transition(.opacity)
                    .modelContainer(container)
                    .environmentObject(purchaseManager)

                } else if let containerLoadError {
                    // If something goes wrong, show a simple error instead of a blank screen
                    VStack(spacing: 12) {
                        Text("Couldn’t start InterviewReady")
                            .font(.headline)
                        Text(containerLoadError)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .padding()
                } else {
                    // SHOW YOUR EXISTING SPLASH IMMEDIATELY
                    SplashScreenView()
                        .transition(.opacity)
                }
            }
            .animation(.easeInOut(duration: 0.5), value: isAppReady)
            .task {
                // Runs once on launch
                await prepareApp()
            }
        }
    }

    @MainActor
    private func prepareApp() async {
        do {
            // Create the SwiftData container AFTER UI is already showing splash
            let schema = Schema([Job.self, Question.self, Story.self, PracticeAttempt.self])
            let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
            let newContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])

            // Seed data
            DataSeeder.shared.seedDataIfNeeded(modelContext: newContainer.mainContext)

            // Switch into the app
            container = newContainer
            isAppReady = true

        } catch {
            containerLoadError = error.localizedDescription
        }
    }
}
