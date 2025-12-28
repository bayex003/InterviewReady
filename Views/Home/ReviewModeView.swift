import SwiftUI
import SwiftData

struct ReviewModeView: View {
    let questions: [Attempt]
    let savedAttempts: [PracticeAttempt]

    @Environment(\.modelContext) private var modelContext

    @State private var selectedAttempt: PracticeAttempt?
    @State private var notesAttempt: PracticeAttempt?
    @State private var notesDraft = ""

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 18) {
                Text("Review Mode")
                    .font(.largeTitle.bold())
                    .foregroundStyle(Color.ink900)

                Text("Review your saved answers and mark the best version.")
                    .font(.subheadline)
                    .foregroundStyle(Color.ink500)

                ForEach(questions) { question in
                    VStack(alignment: .leading, spacing: 12) {
                        Text(question.questionText)
                            .font(.headline)
                            .foregroundStyle(Color.ink900)

                        let answers = answers(for: question)

                        if answers.isEmpty {
                            CardContainer(showShadow: false) {
                                Text("No saved answers for this question.")
                                    .font(.subheadline)
                                    .foregroundStyle(Color.ink500)
                            }
                        } else {
                            VStack(spacing: 12) {
                                ForEach(answers) { attempt in
                                    reviewCard(for: attempt)
                                }
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 32)
        }
        .background(Color.cream50.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $selectedAttempt) { attempt in
            AnswerDetailView(attempt: attempt)
        }
        .sheet(item: $notesAttempt) { attempt in
            ReviewNotesEditor(
                notes: $notesDraft,
                onSave: {
                    attempt.reviewNotes = notesDraft.trimmingCharacters(in: .whitespacesAndNewlines)
                    try? modelContext.save()
                    notesAttempt = nil
                },
                onCancel: {
                    notesAttempt = nil
                }
            )
        }
    }

    private func answers(for question: Attempt) -> [PracticeAttempt] {
        savedAttempts.filter { attempt in
            attempt.questionId == question.questionId || attempt.questionTextSnapshot == question.questionText
        }
        .sorted { $0.createdAt > $1.createdAt }
    }

    @ViewBuilder
    private func reviewCard(for attempt: PracticeAttempt) -> some View {
        CardContainer(showShadow: false) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .center, spacing: 8) {
                    Text(DateFormatters.mediumDateTime.string(from: attempt.createdAt))
                        .font(.caption)
                        .foregroundStyle(Color.ink500)

                    if attempt.isFinal {
                        Chip(title: "Final", isSelected: true)
                    }

                    Spacer()
                }

                Text(answerPreview(for: attempt))
                    .font(.subheadline)
                    .foregroundStyle(Color.ink900)

                if let reviewNotes = attempt.reviewNotes, !reviewNotes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Text(reviewNotes)
                        .font(.caption)
                        .foregroundStyle(Color.ink500)
                }

                HStack(spacing: 12) {
                    Button("Rewrite") {
                        selectedAttempt = attempt
                    }
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.sage500)

                    Button(attempt.isFinal ? "Unmark final" : "Mark as final") {
                        attempt.isFinal.toggle()
                        try? modelContext.save()
                    }
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.ink700)

                    Button("Add notes") {
                        notesDraft = attempt.reviewNotes ?? ""
                        notesAttempt = attempt
                    }
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.ink700)
                }
            }
        }
    }

    private func answerPreview(for attempt: PracticeAttempt) -> String {
        let trimmed = (attempt.notes ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            return "Audio-only answer"
        }
        return trimmed
    }
}

private struct ReviewNotesEditor: View {
    @Binding var notes: String
    let onSave: () -> Void
    let onCancel: () -> Void

    var body: some View {
        NavigationStack {
            ZStack {
                Color.cream50.ignoresSafeArea()

                VStack(alignment: .leading, spacing: 16) {
                    Text("Notes")
                        .font(.title3.bold())
                        .foregroundStyle(Color.ink900)

                    TextEditor(text: $notes)
                        .frame(minHeight: 180)
                        .padding(12)
                        .background(RoundedRectangle(cornerRadius: 16).fill(Color.surfaceWhite))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.ink200, lineWidth: 1)
                        )

                    PrimaryCTAButton(title: "Save notes") {
                        onSave()
                    }
                }
                .padding(20)
            }
            .navigationTitle("Add notes")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        onCancel()
                    }
                }
            }
        }
    }
}
