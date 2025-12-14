import SwiftUI

struct OnboardingView: View {
    @Binding var isOnboardingComplete: Bool
    @State private var currentPage = 0

    // Save name during onboarding (so Home doesn’t need to prompt)
    @AppStorage("userName") private var userName: String = ""
    @AppStorage("hasCompletedNamePrompt_v1") private var hasCompletedNamePrompt: Bool = false

    private let steps: [OnboardingStep] = [
        OnboardingStep(
            image: "briefcase.fill",
            title: "Track Jobs",
            description: "Keep your job applications, stages, interview dates, and notes in one place."
        ),
        OnboardingStep(
            image: "book.closed.fill",
            title: "Capture Moments",
            description: "Save STAR stories so you’re always ready with strong examples."
        ),
        OnboardingStep(
            image: "mic.fill",
            title: "5-Minute Drills",
            description: "Practice with quick drills to build confidence and improve delivery."
        )
    ]

    private var totalPages: Int { steps.count + 1 } // + Name page
    private var isLastPage: Bool { currentPage == totalPages - 1 }
    private var isNamePage: Bool { currentPage == steps.count }

    var body: some View {
        ZStack {
            Color.cream50.ignoresSafeArea()

            VStack(spacing: 0) {
                // Top bar (Skip)
                HStack {
                    Spacer()
                    Button {
                        // If they skip onboarding, keep Home’s name prompt behavior as-is
                        UINotificationFeedbackGenerator().notificationOccurred(.success)
                        isOnboardingComplete = true
                    } label: {
                        Text("Skip")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(Color.ink600)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Skip onboarding")
                }
                .padding(.horizontal)
                .padding(.top, 8)

                // Swipeable content
                TabView(selection: $currentPage) {
                    ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                        OnboardingPage(
                            image: step.image,
                            title: step.title,
                            description: step.description
                        )
                        .tag(index)
                    }

                    NameOnboardingPage(userName: $userName)
                        .tag(steps.count)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                // Bottom controls
                VStack(spacing: 20) {
                    // Dots
                    HStack(spacing: 8) {
                        ForEach(0..<totalPages, id: \.self) { index in
                            Circle()
                                .fill(currentPage == index ? Color.sage500 : Color.sage100)
                                .frame(width: 8, height: 8)
                                .scaleEffect(currentPage == index ? 1.2 : 1.0)
                                .animation(.spring(response: 0.25, dampingFraction: 0.8), value: currentPage)
                        }
                    }

                    // Back / Next row
                    HStack(spacing: 12) {
                        Button {
                            goBack()
                        } label: {
                            Text("Back")
                                .font(.headline)
                                .fontWeight(.bold)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.surfaceWhite)
                                .foregroundStyle(Color.ink900)
                                .overlay(Capsule().strokeBorder(Color.ink200, lineWidth: 1))
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                        .opacity(currentPage == 0 ? 0 : 1)
                        .disabled(currentPage == 0)

                        Button {
                            handleNextButton()
                        } label: {
                            Text(isLastPage ? "Get Started" : "Next")
                                .font(.headline)
                                .fontWeight(.bold)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.sage500)
                                .foregroundColor(.white)
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 18)
                }
                .padding(.top, 10)
            }
        }
    }

    private func goBack() {
        guard currentPage > 0 else { return }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        withAnimation {
            currentPage -= 1
        }
    }

    private func handleNextButton() {
        withAnimation {
            if !isLastPage {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                currentPage += 1
            } else {
                // Finish onboarding
                UINotificationFeedbackGenerator().notificationOccurred(.success)

                // Mark name prompt as completed so Home doesn’t show the alert
                userName = userName.trimmingCharacters(in: .whitespacesAndNewlines)
                hasCompletedNamePrompt = true

                isOnboardingComplete = true
            }
        }
    }
}

// MARK: - Models

private struct OnboardingStep {
    let image: String
    let title: String
    let description: String
}

// MARK: - Pages

struct OnboardingPage: View {
    let image: String
    let title: String
    let description: String

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            ZStack {
                Circle()
                    .fill(Color.sage100)
                    .frame(width: 150, height: 150)

                Image(systemName: image)
                    .font(.system(size: 60))
                    .foregroundStyle(Color.sage500)
            }
            .padding(.bottom, 10)

            VStack(spacing: 12) {
                Text(title)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundStyle(Color.ink900)

                Text(description)
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Color.ink600)
                    .padding(.horizontal, 32)
            }

            Spacer()
        }
        .accessibilityElement(children: .combine)
    }
}

struct NameOnboardingPage: View {
    @Binding var userName: String

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            ZStack {
                Circle()
                    .fill(Color.sage100)
                    .frame(width: 150, height: 150)

                Image(systemName: "person.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(Color.sage500)
            }
            .padding(.bottom, 10)

            VStack(spacing: 12) {
                Text("Personalize")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundStyle(Color.ink900)

                Text("What should we call you?")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Color.ink600)
                    .padding(.horizontal, 32)
            }

            VStack(spacing: 10) {
                TextField("Your name (optional)", text: $userName)
                    .textInputAutocapitalization(.words)
                    .submitLabel(.done)
                    .padding(.vertical, 12)
                    .padding(.horizontal, 14)
                    .background(Color.surfaceWhite)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Color.ink200, lineWidth: 1))
                    .padding(.horizontal, 24)
            }

            Spacer()
        }
    }
}
