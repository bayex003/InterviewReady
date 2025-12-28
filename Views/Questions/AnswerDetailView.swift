import SwiftUI
import SwiftData

struct AnswerDetailView: View {
    @Bindable var attempt: PracticeAttempt

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var isEditing = false
    @State private var draftText = ""
    @State private var showDeleteConfirmation = false
    @State private var audioService = AudioService()

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                header
                questionSection
                answerSection
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 32)
        }
        .background(Color.cream50.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            actionBar
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .onAppear {
            draftText = attempt.notes ?? ""
        }
        .alert("Delete this answer?", isPresented: $showDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                deleteAnswer()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will remove the answer from your history.")
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Saved Answer")
                .font(.largeTitle.bold())
                .foregroundStyle(Color.ink900)

            Text(DateFormatters.mediumDateTime.string(from: attempt.createdAt))
                .font(.subheadline)
                .foregroundStyle(Color.ink500)
        }
    }

    private var questionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Question")
            CardContainer(backgroundColor: Color.surfaceWhite, cornerRadius: 18, showShadow: false) {
                Text(attempt.questionTextSnapshot)
                    .font(.headline)
                    .foregroundStyle(Color.ink900)
                    .lineLimit(3)
            }
        }
    }

    private var answerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Answer")
            CardContainer(backgroundColor: Color.surfaceWhite, cornerRadius: 18, showShadow: false) {
                if isEditing {
                    TextEditor(text: $draftText)
                        .font(.body)
                        .foregroundStyle(Color.ink900)
                        .scrollContentBackground(.hidden)
                        .frame(minHeight: 220)
                } else {
                    Text(answerText)
                        .font(.body)
                        .foregroundStyle(answerText == "No answer saved yet." ? Color.ink400 : Color.ink900)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    private var actionBar: some View {
        VStack(spacing: 12) {
            if let audioPath = attempt.audioPath {
                Button {
                    audioService.playRecording(from: audioPath)
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "play.circle.fill")
                        Text("Play audio")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.sage100)
                    .foregroundStyle(Color.sage500)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .buttonStyle(.plain)
            }

            if isEditing {
                HStack(spacing: 12) {
                    Button("Cancel") {
                        draftText = attempt.notes ?? ""
                        isEditing = false
                    }
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.ink600)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.surfaceWhite)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(Color.ink200, lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .buttonStyle(.plain)

                    Button("Save changes") {
                        saveEdits()
                    }
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(Color.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.sage500)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .buttonStyle(.plain)
                    .disabled(draftText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .opacity(draftText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.6 : 1)
                }
            } else {
                HStack(spacing: 12) {
                    Button("Rewrite") {
                        draftText = attempt.notes ?? ""
                        isEditing = true
                    }
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(Color.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.sage500)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .buttonStyle(.plain)

                    Button("Delete") {
                        showDeleteConfirmation = true
                    }
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(Color.red)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.surfaceWhite)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(Color.red.opacity(0.4), lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .padding(.bottom, 12)
        .background(Color.cream50)
        .overlay(
            Divider()
                .opacity(0.4),
            alignment: .top
        )
    }

    private var answerText: String {
        let trimmed = (attempt.notes ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "No answer saved yet." : trimmed
    }

    private func saveEdits() {
        let trimmed = draftText.trimmingCharacters(in: .whitespacesAndNewlines)
        attempt.notes = trimmed
        try? modelContext.save()
        isEditing = false
    }

    private func deleteAnswer() {
        modelContext.delete(attempt)
        try? modelContext.save()
        dismiss()
    }
}
