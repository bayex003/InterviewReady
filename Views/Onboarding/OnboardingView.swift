import SwiftUI
import Combine

struct OnboardingView: View {
    @Binding var isOnboardingComplete: Bool
    @State private var currentPage = 0

    // Save name during onboarding (so Home doesn’t need to prompt)
    @AppStorage("userName") private var userName: String = ""
    @AppStorage("hasCompletedNamePrompt_v1") private var hasCompletedNamePrompt: Bool = false

    @FocusState private var isNameFieldFocused: Bool
    @State private var keyboardHeight: CGFloat = 0

    private let slides: [OnboardingSlide] = [
        OnboardingSlide(
            titleLine1: "Track",
            titleHighlight: "Applications",
            description: "Organise every role you apply for in one secure place and visualise your progress across stages.",
            ctaTitle: "Start Tracking",
            heroSymbol: "briefcase.fill",
            pills: [
                FeaturePill(symbol: "square.grid.2x2", title: "Stages"),
                FeaturePill(symbol: "calendar", title: "Interview dates")
            ]
        ),
        OnboardingSlide(
            titleLine1: "Build Your",
            titleHighlight: "Story Bank",
            description: "Organise your key career moments using the STAR method. Tag them by skill and have the perfect answer ready for any interview.",
            ctaTitle: "Start Building",
            heroSymbol: "book.closed.fill",
            pills: [
                FeaturePill(symbol: "sparkles", title: "STAR framework"),
                FeaturePill(symbol: "tag.fill", title: "Skill tags")
            ]
        ),
        OnboardingSlide(
            titleLine1: "Practise with",
            titleHighlight: "Purpose",
            description: "Don’t memorise scripts. Link your real-world experiences to top interview questions and build a library of winning answers.",
            ctaTitle: "Start Practising",
            heroSymbol: "mic.fill",
            pills: [
                FeaturePill(symbol: "link", title: "Linked stories"),
                FeaturePill(symbol: "checkmark.seal.fill", title: "STAR-ready answers")
            ]
        )
    ]

    private var totalPages: Int { slides.count + 1 } // + Name page
    private var isLastPage: Bool { currentPage == totalPages - 1 }
    private var isNamePage: Bool { currentPage == slides.count }

    var body: some View {
        ZStack {
            Color.cream50.ignoresSafeArea()

            VStack(spacing: 0) {
                topBar

                TabView(selection: $currentPage) {
                    ForEach(Array(slides.enumerated()), id: \.offset) { index, slide in
                        OnboardingSlideView(slide: slide)
                            .tag(index)
                    }

                    NameOnboardingPage(
                        userName: $userName,
                        isFocused: $isNameFieldFocused,
                        keyboardHeight: keyboardHeight
                    )
                    .tag(slides.count)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .onChange(of: currentPage) { _, newValue in
                    if newValue != slides.count {
                        isNameFieldFocused = false
                    }
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            bottomCTA
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillChangeFrameNotification)) { note in
            keyboardHeight = Self.keyboardHeight(from: note)
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
            keyboardHeight = 0
        }
    }

    // MARK: - Top bar

    private var topBar: some View {
        HStack(alignment: .center) {
            progressPills

            Spacer()

            Button {
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                isNameFieldFocused = false
                hasCompletedNamePrompt = true
                isOnboardingComplete = true
            } label: {
                Text("Skip")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.ink600)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Skip onboarding")
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
        .padding(.bottom, 8)
    }

    private var progressPills: some View {
        HStack(spacing: 8) {
            ForEach(0..<totalPages, id: \.self) { index in
                RoundedRectangle(cornerRadius: 999, style: .continuous)
                    .fill(index == currentPage ? Color.sage500 : Color.ink200.opacity(0.35))
                    .frame(width: index == currentPage ? 26 : 16, height: 6)
                    .animation(.spring(response: 0.25, dampingFraction: 0.9), value: currentPage)
            }
        }
        .accessibilityLabel("Onboarding progress")
    }

    // MARK: - Bottom CTA

    private var bottomCTA: some View {
        VStack(spacing: 10) {
            Button {
                handlePrimaryCTA()
            } label: {
                HStack(spacing: 10) {
                    Text(primaryCTATitle)
                        .font(.headline.weight(.bold))
                    Image(systemName: "arrow.right")
                        .font(.headline.weight(.bold))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.sage500)
                .foregroundStyle(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 20)

            Text("No account needed. Your data stays on this device.")
                .font(.caption)
                .foregroundStyle(Color.ink500)
                .padding(.bottom, 10)
        }
        .padding(.top, 10)
        .background(Color.cream50)
    }

    private var primaryCTATitle: String {
        if isNamePage { return "Get Started" }
        return slides[currentPage].ctaTitle
    }

    private func handlePrimaryCTA() {
        if isNamePage { isNameFieldFocused = false }

        withAnimation {
            if !isLastPage {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                currentPage += 1
            } else {
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                userName = userName.trimmingCharacters(in: .whitespacesAndNewlines)
                hasCompletedNamePrompt = true
                isOnboardingComplete = true
            }
        }
    }

    private static func keyboardHeight(from notification: Notification) -> CGFloat {
        guard let frame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return 0 }
        return max(0, frame.height)
    }
}

// MARK: - Models

private struct OnboardingSlide: Identifiable, Hashable {
    let id = UUID()
    let titleLine1: String
    let titleHighlight: String
    let description: String
    let ctaTitle: String
    let heroSymbol: String
    let pills: [FeaturePill]
}

private struct FeaturePill: Identifiable, Hashable {
    let id = UUID()
    let symbol: String
    let title: String
}

// MARK: - Slide UI

private struct OnboardingSlideView: View {
    let slide: OnboardingSlide

    var body: some View {
        VStack(spacing: 16) {
            hero

            VStack(spacing: 10) {
                title

                Text(slide.description)
                    .font(.subheadline)
                    .foregroundStyle(Color.ink600)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 26)
            }

            pillsRow

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 20)
        .padding(.top, 6)
        .padding(.bottom, 20)
    }

    private var hero: some View {
        RoundedRectangle(cornerRadius: 26, style: .continuous)
            .fill(Color.sage100.opacity(0.55))
            .frame(maxWidth: .infinity)
            .frame(height: 210)
            .overlay(
                ZStack {
                    Circle()
                        .fill(Color.surfaceWhite)
                        .frame(width: 46, height: 46)

                    Image(systemName: slide.heroSymbol)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(Color.sage500)
                }
            )
            .padding(.top, 4)
    }

    private var title: some View {
        VStack(spacing: 2) {
            Text(slide.titleLine1)
                .font(.largeTitle.weight(.heavy))
                .foregroundStyle(Color.ink900)

            Text(slide.titleHighlight)
                .font(.largeTitle.weight(.heavy))
                .foregroundStyle(Color.sage500)
        }
        .multilineTextAlignment(.center)
        .lineLimit(2)
        .minimumScaleFactor(0.85)
        .padding(.top, 2)
    }

    private var pillsRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(slide.pills) { pill in
                    FeaturePillView(pill: pill)
                }
            }
            // Centre the content when it fits; still scrolls if it doesn’t
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.top, 10)
        }
    }
}

private struct FeaturePillView: View {
    let pill: FeaturePill

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: pill.symbol)
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.sage500)

            Text(pill.title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.ink700)
                .lineLimit(1)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.surfaceWhite)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.ink200, lineWidth: 1)
        )
    }
}

// MARK: - Name page (top-level, not nested)

private struct NameOnboardingPage: View {
    @Binding var userName: String
    @FocusState.Binding var isFocused: Bool
    let keyboardHeight: CGFloat

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    RoundedRectangle(cornerRadius: 26, style: .continuous)
                        .fill(Color.sage100.opacity(0.55))
                        .frame(maxWidth: .infinity)
                        .frame(height: 190)
                        .overlay(
                            ZStack {
                                Circle()
                                    .fill(Color.surfaceWhite)
                                    .frame(width: 46, height: 46)

                                Image(systemName: "person.fill")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundStyle(Color.sage500)
                            }
                        )
                        .padding(.top, 4)

                    VStack(spacing: 8) {
                        Text("Personalise")
                            .font(.largeTitle.weight(.heavy))
                            .foregroundStyle(Color.ink900)

                        Text("your Home")
                            .font(.largeTitle.weight(.heavy))
                            .foregroundStyle(Color.sage500)

                        Text("What should we call you? This is optional.")
                            .font(.subheadline)
                            .foregroundStyle(Color.ink600)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 26)
                    }

                    TextField("Your name (optional)", text: $userName)
                        .id("nameField")
                        .textInputAutocapitalization(.words)
                        .submitLabel(.done)
                        .focused($isFocused)
                        .padding(.vertical, 14)
                        .padding(.horizontal, 14)
                        .background(Color.surfaceWhite)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(Color.ink200, lineWidth: 1)
                        )
                        .onSubmit { isFocused = false }

                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, max(24, keyboardHeight + 40))
                .onChange(of: isFocused) { _, focused in
                    if focused {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                proxy.scrollTo("nameField", anchor: .center)
                            }
                        }
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture { isFocused = false }
            }
        }
    }
}
