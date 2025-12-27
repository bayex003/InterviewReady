import SwiftUI

struct SessionSummaryView: View {
    let attempts: [Attempt]
    let durationSeconds: Int
    let onRetry: () -> Void
    let onExit: () -> Void

    @ObservedObject var attemptsStore: AttemptsStore

    @AppStorage("savedSessionCount") private var savedSessionCount = 0

    @State private var hasSaved = false
    @State private var showAttemptsList = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {
                header

                statsSection

                questionsSection

                actionsSection
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 32)
        }
        .background(Color.cream50.ignoresSafeArea())
        .navigationBarBackButtonHidden(true)
        .navigationDestination(isPresented: $showAttemptsList) {
            AttemptsListView(attemptsStore: attemptsStore)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Session Summary")
                .font(.largeTitle.bold())
                .foregroundStyle(Color.ink900)

            Text("Here’s how this round of practice went.")
                .font(.subheadline)
                .foregroundStyle(Color.ink500)
        }
    }

    private var statsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Session Stats")

            HStack(spacing: 12) {
                statCard(title: "Questions", value: "\(attempts.count)")
                statCard(title: "Duration", value: formattedDuration(durationSeconds))
                statCard(title: "Mode", value: modeSummary)
            }
        }
    }

    private func statCard(title: String, value: String) -> some View {
        CardContainer(backgroundColor: Color.surfaceWhite, cornerRadius: 18, showShadow: false) {
            VStack(alignment: .leading, spacing: 6) {
                Text(value)
                    .font(.headline.weight(.bold))
                    .foregroundStyle(Color.ink900)

                Text(title)
                    .font(.caption)
                    .foregroundStyle(Color.ink500)
            }
        }
    }

    private var questionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Questions Attempted")

            VStack(spacing: 12) {
                ForEach(attempts) { attempt in
                    CardContainer(backgroundColor: Color.surfaceWhite, cornerRadius: 18, showShadow: false) {
                        VStack(alignment: .leading, spacing: 10) {
                            Text(attempt.questionText)
                                .font(.headline)
                                .foregroundStyle(Color.ink900)
                                .lineLimit(2)

                            HStack(spacing: 8) {
                                Chip(title: attempt.category, isSelected: true)
                                Chip(title: attempt.mode.title, isSelected: false)
                            }
                        }
                    }
                }
            }
        }
    }

    private var actionsSection: some View {
        VStack(spacing: 12) {
            PrimaryCTAButton(title: hasSaved ? "Attempts Saved" : "Save Attempt(s)") {
                saveAttempts()
            }
            .disabled(hasSaved)

            HStack(spacing: 12) {
                secondaryButton(title: "Retry Session", action: onRetry)
                secondaryButton(title: "Back to Question Bank", action: onExit)
            }
        }
    }

    private func secondaryButton(title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.headline)
                .foregroundStyle(Color.ink700)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.surfaceWhite)
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color.ink200, lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private func saveAttempts() {
        guard !hasSaved else { return }
        attemptsStore.add(attempts)
        hasSaved = true
        savedSessionCount += 1
        showAttemptsList = true
    }

    private var modeSummary: String {
        let uniqueModes = Set(attempts.map { $0.mode })
        if uniqueModes.count == 1 {
            return uniqueModes.first?.title ?? "Mixed"
        }
        return "Mixed"
    }

    private func formattedDuration(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        if minutes > 0 {
            return String(format: "%dm %02ds", minutes, remainingSeconds)
        }
        return String(format: "%ds", remainingSeconds)
    }
}
