import SwiftUI

struct AttemptDetailView: View {
    let attempt: Attempt
    @ObservedObject var attemptsStore: AttemptsStore

    @Environment(\.dismiss) private var dismiss
    @State private var showDeleteConfirmation = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                header
                questionSection
                detailsSection
                notesSection
                linkedStorySection
                deleteSection
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 32)
        }
        .background(Color.cream50.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .alert("Delete this attempt?", isPresented: $showDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                attemptsStore.delete(attempt)
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will remove the attempt from your history.")
        }
    }

    private var header: some View {
        Text("Attempt Detail")
            .font(.largeTitle.bold())
            .foregroundStyle(Color.ink900)
    }

    private var questionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Question")
            CardContainer(backgroundColor: Color.surfaceWhite, cornerRadius: 18, showShadow: false) {
                Text(attempt.questionText)
                    .font(.headline)
                    .foregroundStyle(Color.ink900)
            }
        }
    }

    private var detailsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Details")
            CardContainer(backgroundColor: Color.surfaceWhite, cornerRadius: 18, showShadow: false) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Chip(title: attempt.mode.title, isSelected: true)
                        Chip(title: attempt.category, isSelected: false)
                    }

                    Text("Duration: \(formattedDuration)")
                        .font(.subheadline)
                        .foregroundStyle(Color.ink700)

                    Text("Completed: \(formattedDate)")
                        .font(.subheadline)
                        .foregroundStyle(Color.ink500)
                }
            }
        }
    }

    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Transcript / Notes")
            CardContainer(backgroundColor: Color.surfaceWhite, cornerRadius: 18, showShadow: false) {
                Text(notesText)
                    .font(.subheadline)
                    .foregroundStyle(notesText == "No notes captured yet." ? Color.ink400 : Color.ink700)
            }
        }
    }

    private var linkedStorySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Linked Story")
            CardContainer(backgroundColor: Color.surfaceWhite, cornerRadius: 18, showShadow: false) {
                Text("Link a story")
                    .font(.subheadline)
                    .foregroundStyle(Color.ink500)
            }
        }
    }

    private var deleteSection: some View {
        Button {
            showDeleteConfirmation = true
        } label: {
            Text("Delete Attempt")
                .font(.headline)
                .foregroundStyle(Color.red)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.surfaceWhite)
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color.red.opacity(0.4), lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
        .padding(.top, 4)
    }

    private var notesText: String {
        let trimmed = attempt.notes?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return trimmed.isEmpty ? "No notes captured yet." : trimmed
    }

    private var formattedDuration: String {
        let minutes = attempt.durationSeconds / 60
        let seconds = attempt.durationSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: attempt.timestamp)
    }
}
