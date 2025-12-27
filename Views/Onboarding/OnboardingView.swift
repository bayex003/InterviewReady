import SwiftUI

struct OnboardingView: View {
    @Binding var isOnboardingComplete: Bool
    @State private var currentPage = 0

    // Save name during onboarding (so Home doesn’t need to prompt)
    @AppStorage("userName") private var userName: String = ""
    @AppStorage("hasCompletedNamePrompt_v1") private var hasCompletedNamePrompt: Bool = false
    @FocusState private var isNameFieldFocused: Bool

    private let steps: [OnboardingStep] = [
        OnboardingStep(
            titleLeading: "Build Your",
            titleAccent: "Story Bank",
            description: "Organize your key career moments using the STAR method. Tag them by skill and keep them private.",
            pills: ["STAR Framework", "Skill Tags", "Private"],
            hero: HeroContent(
                eyebrow: "STAR STORY",
                title: "Product Launch Wins",
                subtitle: "Tagged with Leadership",
                symbol: "star.fill"
            )
        ),
        OnboardingStep(
            titleLeading: "Practice With",
            titleAccent: "Purpose",
            description: "Run focused drills, link questions to stories, and build confidence for the real thing.",
            pills: ["5-Minute Drills", "Speak / Write", "Track Progress"],
            hero: HeroContent(
                eyebrow: "INTERVIEW QUESTION",
                title: "Greatest Weakness?",
                subtitle: "Linked to Growth Story",
                symbol: "link"
            )
        ),
        OnboardingStep(
            titleLeading: "Stay",
            titleAccent: "Interview Ready",
            description: "Keep jobs, stories, and practice attempts together so you’re always ready.",
            pills: ["Jobs", "Stories", "Attempts"],
            hero: HeroContent(
                eyebrow: "PREP HUB",
                title: "All-in-One Ready",
                subtitle: "Applications • Stories • Drills",
                symbol: "checkmark.seal.fill"
            )
        )
    ]

    private var totalPages: Int { steps.count + 1 } // + Name page
    private var isLastPage: Bool { currentPage == totalPages - 1 }

    var body: some View {
        ZStack {
            Color.cream50.ignoresSafeArea()

            VStack(spacing: 0) {
                topBar

                TabView(selection: $currentPage) {
                    ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                        OnboardingPage(step: step)
                            .tag(index)
                    }

                    NameOnboardingPage(userName: $userName, isNameFieldFocused: $isNameFieldFocused)
                        .tag(steps.count)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                bottomCTA
            }
        }
        .onChange(of: currentPage) { newValue in
            if newValue == steps.count {
                isNameFieldFocused = true
            } else {
                isNameFieldFocused = false
            }
        }
    }

    private var topBar: some View {
        HStack(spacing: 12) {
            ProgressIndicatorView(totalSteps: totalPages, currentStep: currentPage)

            Spacer()

            Button {
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                hasCompletedNamePrompt = true
                isNameFieldFocused = false
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
        .padding(.horizontal, 20)
        .padding(.top, 12)
    }

    private var bottomCTA: some View {
        VStack(spacing: 14) {
            Button {
                handleNextButton()
            } label: {
                HStack(spacing: 8) {
                    Text(isLastPage ? "Get Started" : "Next")
                        .font(.headline)
                        .fontWeight(.bold)
                    Image(systemName: "chevron.right")
                        .font(.headline.weight(.bold))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.sage500)
                .foregroundStyle(Color.surfaceWhite)
                .clipShape(Capsule())
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 24)
            .padding(.bottom, 18)
        }
    }

    private func handleNextButton() {
        withAnimation {
            if !isLastPage {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                currentPage += 1
            } else {
                UINotificationFeedbackGenerator().notificationOccurred(.success)

                userName = userName.trimmingCharacters(in: .whitespacesAndNewlines)
                hasCompletedNamePrompt = true
                isNameFieldFocused = false

                isOnboardingComplete = true
            }
        }
    }
}

// MARK: - Models

private struct OnboardingStep {
    let titleLeading: String
    let titleAccent: String
    let description: String
    let pills: [String]
    let hero: HeroContent
}

private struct HeroContent {
    let eyebrow: String
    let title: String
    let subtitle: String
    let symbol: String
}

// MARK: - Components

private struct ProgressIndicatorView: View {
    let totalSteps: Int
    let currentStep: Int

    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<totalSteps, id: \.self) { index in
                Capsule()
                    .fill(index <= currentStep ? Color.sage500 : Color.sage100)
                    .frame(width: index == currentStep ? 36 : 20, height: 6)
                    .animation(.spring(response: 0.3, dampingFraction: 0.8), value: currentStep)
            }
        }
        .accessibilityLabel("Onboarding progress")
    }
}

private struct FeaturePill: View {
    let title: String

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(Color.sage500)
                .frame(width: 6, height: 6)
            Text(title)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(Color.ink700)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.surfaceWhite)
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .strokeBorder(Color.ink200, lineWidth: 1)
        )
    }
}

private struct HeroCard: View {
    let content: HeroContent

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Image(systemName: content.symbol)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Color.sage500)
                    .padding(8)
                    .background(Color.sage100)
                    .clipShape(Circle())

                Text(content.eyebrow)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.ink600)
            }

            Text(content.title)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundStyle(Color.ink900)

            Text(content.subtitle)
                .font(.subheadline)
                .foregroundStyle(Color.ink600)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.surfaceWhite)
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .strokeBorder(Color.ink200, lineWidth: 1)
                )
                .shadow(color: Color.ink200.opacity(0.25), radius: 12, x: 0, y: 8)
        )
    }
}

// MARK: - Pages

struct OnboardingPage: View {
    let step: OnboardingStep

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {
                HeroCard(content: step.hero)
                    .padding(.top, 24)

                VStack(spacing: 12) {
                    VStack(spacing: 6) {
                        Text(step.titleLeading)
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundStyle(Color.ink900)

                        Text(step.titleAccent)
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundStyle(Color.sage500)
                    }

                    Text(step.description)
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(Color.ink600)
                        .padding(.horizontal, 32)
                }

                HStack(spacing: 10) {
                    ForEach(step.pills, id: \.self) { pill in
                        FeaturePill(title: pill)
                    }
                }

                Spacer(minLength: 20)
            }
            .padding(.horizontal, 24)
            .frame(maxWidth: .infinity)
        }
    }
}

struct NameOnboardingPage: View {
    @Binding var userName: String
    @FocusState.Binding var isNameFieldFocused: Bool

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {
                HeroCard(
                    content: HeroContent(
                        eyebrow: "PROFILE",
                        title: "Set your name",
                        subtitle: "Make InterviewReady feel personal",
                        symbol: "person.fill"
                    )
                )
                .padding(.top, 24)

                VStack(spacing: 12) {
                    VStack(spacing: 6) {
                        Text("Personalise")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundStyle(Color.ink900)

                        Text("Your experience")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundStyle(Color.sage500)
                    }

                    Text("What should we call you? You can always change this later.")
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(Color.ink600)
                        .padding(.horizontal, 32)
                }

                VStack(spacing: 12) {
                    TextField("Your name (optional)", text: $userName)
                        .textInputAutocapitalization(.words)
                        .submitLabel(.done)
                        .padding(.vertical, 14)
                        .padding(.horizontal, 16)
                        .background(Color.surfaceWhite)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Color.ink200, lineWidth: 1))
                        .focused($isNameFieldFocused)
                        .padding(.horizontal, 8)

                    HStack(spacing: 10) {
                        FeaturePill(title: "Optional")
                        FeaturePill(title: "Private")
                    }
                }

                Spacer(minLength: 20)
            }
            .padding(.horizontal, 24)
            .frame(maxWidth: .infinity)
        }
        .onTapGesture {
            isNameFieldFocused = false
        }
    }
}
