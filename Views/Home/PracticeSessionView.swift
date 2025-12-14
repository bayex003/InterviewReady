import SwiftUI
import SwiftData

struct PracticeSessionView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme

    // Audio
    @State private var audioService = AudioService()

    // Data
    @Query var allQuestions: [Question]
    @State private var sessionQuestions: [Question] = []

    // State
    @State private var currentIndex = 0
    @State private var showFeedback = false
    @State private var isFinished = false
    @State private var showExitAlert = false

    // Use a true dark surface for buttons in Dark Mode (prevents white-on-white)
    private var primaryDarkSurface: Color {
        colorScheme == .dark ? Color.black : Color.ink900
    }

    private var currentQuestion: Question? {
        guard !sessionQuestions.isEmpty, currentIndex < sessionQuestions.count else { return nil }
        return sessionQuestions[currentIndex]
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.cream50.ignoresSafeArea()

                if sessionQuestions.isEmpty {
                    Text("Loading drill...")
                        .foregroundStyle(Color.ink900)

                } else if isFinished {
                    DrillFinishedView(dismiss: dismiss)

                } else {
                    VStack(spacing: 24) {

                        // TOP BAR
                        HStack {
                            Button { showExitAlert = true } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.title2)
                                    .foregroundStyle(Color.ink400)
                            }

                            Spacer()

                            Text("QUESTION \(currentIndex + 1) OF \(sessionQuestions.count)")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundStyle(Color.ink600)

                            Spacer()

                            // Spacer icon to keep title centered
                            Image(systemName: "xmark.circle.fill")
                                .font(.title2)
                                .opacity(0)
                        }
                        .padding(.horizontal)
                        .padding(.top, 10)

                        ProgressView(value: Double(currentIndex + 1), total: Double(sessionQuestions.count))
                            .tint(Color.sage500)
                            .padding(.horizontal)

                        // THE CARD
                        ScrollView {
                            VStack(spacing: 20) {
                                if let question = currentQuestion {
                                    Text(question.category.uppercased())
                                        .font(.caption)
                                        .fontWeight(.bold)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(Color.sage500.opacity(0.2))
                                        .foregroundStyle(Color.sage500)
                                        .clipShape(Capsule())

                                    Text(question.text)
                                        .font(.title3)
                                        .fontWeight(.semibold)
                                        .multilineTextAlignment(.center)
                                        .foregroundStyle(Color.ink900)
                                        .padding(.horizontal)

                                    // FEEDBACK (after recording)
                                    if showFeedback {
                                        VStack(alignment: .leading, spacing: 12) {
                                            Divider()

                                            // PLAYBACK
                                            if audioService.recordedFileURL != nil {
                                                Button {
                                                    audioService.playRecording()
                                                } label: {
                                                    HStack {
                                                        Image(systemName: audioService.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                                                            .font(.title2)

                                                        Text(audioService.isPlaying ? "Playing..." : "Hear your answer")
                                                            .fontWeight(.medium)
                                                    }
                                                    .frame(maxWidth: .infinity)
                                                    .padding()
                                                    .background(Color.blue.opacity(0.1))
                                                    .foregroundColor(.blue)
                                                    .cornerRadius(12)
                                                }
                                                .padding(.bottom, 8)
                                            }

                                            Text("Did you include?")
                                                .font(.headline)
                                                .foregroundStyle(Color.ink600)

                                            ChecklistItem(text: "Situation: Set the scene?", isChecked: false)
                                            ChecklistItem(text: "Task: What was the challenge?", isChecked: false)
                                            ChecklistItem(text: "Action: What did YOU do?", isChecked: false)
                                            ChecklistItem(text: "Result: What was the outcome?", isChecked: false)
                                        }
                                        .padding(.top, 10)
                                        .transition(.opacity)
                                    }
                                }
                            }
                            .padding(24)
                            .frame(maxWidth: .infinity)
                            .background(Color.surfaceWhite)
                            .cornerRadius(24)
                            .shadow(color: Color.black.opacity(0.08), radius: 12, y: 4)
                            .padding(.horizontal)
                        }

                        Spacer()

                        // CONTROLS
                        VStack(spacing: 20) {
                            if audioService.isRecording {
                                Button { stopRecording() } label: {
                                    VStack {
                                        Image(systemName: "stop.circle.fill")
                                            .font(.system(size: 70))
                                            .foregroundStyle(Color.red)
                                            .background(Color.white)
                                            .clipShape(Circle())

                                        Text("Tap to Stop")
                                            .fontWeight(.medium)
                                            .foregroundStyle(Color.ink900)
                                    }
                                }

                            } else if showFeedback {
                                HStack(spacing: 20) {
                                    Button { retryQuestion() } label: {
                                        VStack {
                                            Image(systemName: "arrow.counterclockwise.circle.fill")
                                                .font(.system(size: 50))
                                                .foregroundStyle(Color.ink400)
                                                .background(Color.white)
                                                .clipShape(Circle())

                                            Text("Try Again")
                                                .font(.caption)
                                                .foregroundStyle(Color.ink600)
                                        }
                                    }

                                    Button { nextQuestion() } label: {
                                        HStack {
                                            Text("Next")
                                                .fontWeight(.bold)
                                            Image(systemName: "arrow.right")
                                        }
                                        .padding(.vertical, 16)
                                        .padding(.horizontal, 32)
                                        .background(primaryDarkSurface)   // ✅ dark-mode safe
                                        .foregroundStyle(.white)
                                        .clipShape(Capsule())
                                        .shadow(radius: 5)
                                    }
                                }

                            } else {
                                Button { startRecording() } label: {
                                    Image(systemName: "mic.circle.fill")
                                        .font(.system(size: 70))
                                        .foregroundStyle(Color.sage500)
                                        .background(Color.white)
                                        .clipShape(Circle())
                                        .shadow(color: Color.sage500.opacity(0.3), radius: 10, y: 5)
                                }
                            }
                        }
                        .padding(.bottom, 40)
                    }
                }
            }
            .navigationBarHidden(true)
            .onAppear { startSession() }
            .alert("End Session?", isPresented: $showExitAlert) {
                Button("Cancel", role: .cancel) { }
                Button("End Drill", role: .destructive) { dismiss() }
            } message: {
                Text("Your progress will be lost.")
            }
        }
    }

    // MARK: - Logic

    private func startSession() {
        if allQuestions.count >= 3 {
            sessionQuestions = Array(allQuestions.shuffled().prefix(3))
        } else {
            sessionQuestions = allQuestions
        }
        currentIndex = 0
        isFinished = false
        showFeedback = false
    }

    private func startRecording() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        let uniqueID = UUID().uuidString
        audioService.startRecording(id: uniqueID)
        withAnimation { showFeedback = false }
    }

    private func stopRecording() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        audioService.stopRecording()

        markCurrentQuestionAsPracticed()

        withAnimation { showFeedback = true }
    }

    private func markCurrentQuestionAsPracticed() {
        guard let q = currentQuestion else { return }

        if q.isAnswered == false {
            q.isAnswered = true
        }
        q.dateAnswered = Date()

        do {
            try modelContext.save()
        } catch {
            print("❌ Failed to save practiced question: \(error)")
        }
    }

    private func retryQuestion() {
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
        withAnimation { showFeedback = false }
    }

    private func nextQuestion() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        showFeedback = false

        if currentIndex < sessionQuestions.count - 1 {
            withAnimation { currentIndex += 1 }
        } else {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            isFinished = true
        }
    }
}

// MARK: - Subviews

struct ChecklistItem: View {
    let text: String
    @State var isChecked: Bool

    var body: some View {
        Button { withAnimation { isChecked.toggle() } } label: {
            HStack {
                Image(systemName: isChecked ? "checkmark.square.fill" : "square")
                    .foregroundStyle(isChecked ? Color.sage500 : Color.ink400)
                Text(text)
                    .foregroundStyle(Color.ink900)
                    .strikethrough(isChecked)
                Spacer()
            }
        }
    }
}

struct DrillFinishedView: View {
    var dismiss: DismissAction

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundStyle(Color.sage500)

            Text("Drill Complete!")
                .font(.title)
                .fontWeight(.bold)
                .foregroundStyle(Color.ink900)

            Button { dismiss() } label: {
                Text("Done")
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.sage500)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 40)
        }
    }
}
