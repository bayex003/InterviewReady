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
    @AppStorage("firstLaunchDate") private var firstLaunchDate: Double = 0

    @StateObject private var purchaseManager = PurchaseManager()
    @StateObject private var dataController = AppDataController()
    @StateObject private var jobsStore = JobsStore()

    // Fade transition into the real app
    @State private var isAppReady = false

    var body: some Scene {
        WindowGroup {
            ZStack {
                if let container = dataController.container {
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
                    .environmentObject(dataController)
                    .environmentObject(jobsStore)

                } else if let containerLoadError = dataController.loadError {
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
            .onChange(of: dataController.container != nil) { _, newValue in
                if newValue {
                    isAppReady = true
                }
            }
            .onChange(of: purchaseManager.isPro) { _, isPro in
                if isPro {
                    Task {
                        await dataController.switchToCloudIfPro()
                    }
                }
            }
            .task {
                if firstLaunchDate == 0 {
                    firstLaunchDate = Date().timeIntervalSince1970
                }
                await prepareApp()
            }
        }
    }

    @MainActor
    private func prepareApp() async {
        await dataController.loadInitialContainer()
    }
}
