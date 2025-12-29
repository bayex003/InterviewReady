import SwiftUI

// MARK: - AnswerDetailView
/// Used by:
/// - PracticeSessionView: `.sheet(item: $selectedAttempt) { AnswerDetailView(attempt: attempt) }`
/// - SessionSummaryView: `NavigationLink { AnswerDetailView(attempt: attempt) }`
struct AnswerDetailView: View {
    let attempt: PracticeAttempt
    @Environment(\.dismiss) private var dismiss

    private var notesText: String {
        (attempt.notes ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 16) {
                Text("Answer")
                    .font(.largeTitle.bold())
                    .foregroundStyle(Color.ink900)

                Text(attempt.questionTextSnapshot)
                    .font(.headline)
                    .foregroundStyle(Color.ink900)

                CardContainer(showShadow: false) {
                    if notesText.isEmpty {
                        Text("No written notes for this answer.")
                            .font(.subheadline)
                            .foregroundStyle(Color.ink500)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    } else {
                        Text(notesText)
                            .font(.body)
                            .foregroundStyle(Color.ink900)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }

                if let seconds = attempt.durationSeconds, seconds > 0 {
                    Text("Duration: \(seconds)s")
                        .font(.caption)
                        .foregroundStyle(Color.ink500)
                }

                Text(attempt.createdAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundStyle(Color.ink500)

                Spacer(minLength: 24)
            }
            .padding(20)
        }
        .background(Color.cream50.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Done") { dismiss() }
            }
        }
    }
}

// MARK: - ReviewModeView
/// Used by SessionSummaryView:
/// `ReviewModeView(questions: attempts, savedAttempts: savedAttempts)`
struct ReviewModeView: View {
    let questions: [Attempt]
    let savedAttempts: [PracticeAttempt]

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 16) {
                Text("Review Mode")
                    .font(.largeTitle.bold())
                    .foregroundStyle(Color.ink900)

                Text("Review your session questions and saved answers.")
                    .font(.subheadline)
                    .foregroundStyle(Color.ink500)

                if questions.isEmpty {
                    CardContainer(showShadow: false) {
                        Text("No questions to review.")
                            .font(.subheadline)
                            .foregroundStyle(Color.ink500)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                } else {
                    VStack(spacing: 12) {
                        ForEach(questions) { attempt in
                            CardContainer(showShadow: false) {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text(attempt.questionText)
                                        .font(.headline)
                                        .foregroundStyle(Color.ink900)
                                        .lineLimit(3)

                                    HStack(spacing: 8) {
                                        Chip(title: attempt.category, isSelected: true)
                                        Chip(title: attempt.mode.title, isSelected: false)
                                    }
                                }
                            }
                        }
                    }
                }

                if !savedAttempts.isEmpty {
                    Divider().opacity(0.4)

                    Text("Saved answers")
                        .font(.headline)
                        .foregroundStyle(Color.ink900)

                    VStack(spacing: 12) {
                        ForEach(savedAttempts) { attempt in
                            NavigationLink {
                                AnswerDetailView(attempt: attempt)
                            } label: {
                                CardContainer(showShadow: false) {
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text(attempt.questionTextSnapshot)
                                            .font(.headline)
                                            .foregroundStyle(Color.ink900)
                                            .lineLimit(2)

                                        Text(attempt.createdAt.formatted(date: .abbreviated, time: .shortened))
                                            .font(.caption)
                                            .foregroundStyle(Color.ink500)
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                Spacer(minLength: 24)
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 24)
        }
        .background(Color.cream50.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
    }
}
