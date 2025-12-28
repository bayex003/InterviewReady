import SwiftUI

/// NOTE:
/// This file is self-contained to avoid dependency breakage from renamed components.
/// (No SectionHeader / PrimaryCTAButton / Chip / CardContainer usage.)
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
            AttemptsListDestinationView(attemptsStore: attemptsStore)
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

    // MARK: - Stats

    private var statsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("Session Stats")

            HStack(spacing: 12) {
                statCard(title: "Questions", value: "\(attempts.count)")
                statCard(title: "Duration", value: formattedDuration(durationSeconds))
                statCard(title: "Mode", value: modeSummary)
            }
        }
    }

    private func statCard(title: String, value: String) -> some View {
        SummaryCard {
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

    // MARK: - Attempts

    private var questionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("Questions Attempted")

            VStack(spacing: 12) {
                ForEach(attempts) { attempt in
                    SummaryCard {
                        VStack(alignment: .leading, spacing: 10) {
                            Text(attempt.questionText)
                                .font(.headline)
                                .foregroundStyle(Color.ink900)
                                .lineLimit(2)

                            HStack(spacing: 8) {
                                SummaryPill(text: attempt.category, isEmphasis: true)
                                SummaryPill(text: attempt.mode.title, isEmphasis: false)
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Actions

    private var actionsSection: some View {
        VStack(spacing: 12) {
            primaryButton(title: hasSaved ? "Attempts Saved" : "Save Attempt(s)", isDisabled: hasSaved) {
                saveAttempts()
            }

            HStack(spacing: 12) {
                secondaryButton(title: "Retry Session", action: onRetry)
                secondaryButton(title: "Back to Question Bank", action: onExit)
            }
        }
    }

    private func primaryButton(title: String, isDisabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.headline.weight(.semibold))
                .foregroundStyle(Color.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color.sage500.opacity(isDisabled ? 0.45 : 1.0))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
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

    // MARK: - Helpers

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

    private func sectionTitle(_ text: String) -> some View {
        Text(text.uppercased())
            .font(.caption)
            .foregroundStyle(Color.ink500)
            .padding(.bottom, 2)
    }
}

// MARK: - Destination

struct AttemptsListDestinationView: View {
    @ObservedObject var attemptsStore: AttemptsStore

    var body: some View {
        AttemptsListView()
            .environmentObject(attemptsStore)
    }
}

// MARK: - Local UI building blocks (avoid cross-file init mismatches)

private struct SummaryCard<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.surfaceWhite)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Color.ink200.opacity(0.6), lineWidth: 1)
            )
    }
}

private struct SummaryPill: View {
    let text: String
    let isEmphasis: Bool

    var body: some View {
        Text(text)
            .font(.caption.weight(.semibold))
            .foregroundStyle(isEmphasis ? Color.ink900 : Color.ink700)
            .padding(.vertical, 6)
            .padding(.horizontal, 10)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(isEmphasis ? Color.sage100.opacity(0.6) : Color.ink100.opacity(0.25))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(isEmphasis ? Color.sage500.opacity(0.45) : Color.ink200, lineWidth: 1)
            )
    }
}

