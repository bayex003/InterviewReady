import SwiftUI
import SwiftData

struct PracticeSessionView: View {
    let questions: [QuestionBankItem]

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var purchaseManager: PurchaseManager
    @Query(sort: \Story.lastUpdated, order: .reverse) private var stories: [Story]

    @State private var currentIndex = 0
    @State private var inputMode: InputMode = .speak
    @State private var isPaused = false
    @State private var responseText = ""
    @State private var minutes = 1
    @State private var seconds = 45
    @State private var sessionStart = Date()
    @State private var completedQuestions: [QuestionBankItem] = []
    @State private var questionModes: [UUID: InputMode] = [:]
    @State private var draftsByQuestionId: [UUID: String] = [:]
    @State private var linkedStoryByQuestionId: [UUID: Story] = [:]
    @State private var summaryAttempts: [Attempt] = []
    @State private var summaryDurationSeconds = 0
    @State private var showSummary = false
    @State private var savedAttempts: [PracticeAttempt] = []
    @State private var showStoryPicker = false
    @State private var savedQuestionId: UUID?
    @State private var lastSavedAttemptByQuestionId: [UUID: PracticeAttempt] = [:]
    @State private var selectedAttempt: PracticeAttempt?
    @State private var showTips = false

    private let freeAnswerLimitPerQuestion = 3

    private var currentQuestion: QuestionBankItem {
        questions.indices.contains(currentIndex) ? questions[currentIndex] : .empty
    }

    private var totalQuestions: Int {
        max(questions.count, 1)
    }

    private var progressValue: Double {
        guard totalQuestions > 0 else { return 0 }
        return Double(min(currentIndex + 1, totalQuestions)) / Double(totalQuestions)
    }

    var body: some View {
        VStack(spacing: 0) {
            topBar
                .padding(.horizontal, 20)
                .padding(.top, 12)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    questionMeta
                    progressBar
                    questionCard
                    tipsPanel
                    inputModeToggle
                    inputArea
                    linkedStoryCard
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 32)
            }
            .tapToDismissKeyboard()
        }
        .background(Color.cream50.ignoresSafeArea())
        .navigationBarBackButtonHidden(true)
        .safeAreaInset(edge: .bottom) {
            actionBar
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .navigationDestination(isPresented: $showSummary) {
            SessionSummaryView(
                attempts: summaryAttempts,
                savedAttempts: savedAttempts,
                durationSeconds: summaryDurationSeconds,
                onRetry: resetSession,
                onExit: dismissToQuestionBank
            )
        }
        .sheet(isPresented: $showStoryPicker) {
            StoryPickerSheet(
                stories: stories,
                selectedStoryId: linkedStoryByQuestionId[currentQuestion.id]?.id,
                onSelect: { story in
                    linkedStoryByQuestionId[currentQuestion.id] = story
                    showStoryPicker = false
                }
            )
        }
        .sheet(item: $selectedAttempt) { attempt in
            AnswerDetailView(attempt: attempt)
        }
        .onChange(of: currentIndex) { _, _ in
            loadDraftForCurrentQuestion()
            showTips = false
        }
        .onChange(of: responseText) { _, newValue in
            draftsByQuestionId[currentQuestion.id] = newValue
            if savedQuestionId == currentQuestion.id {
                savedQuestionId = nil
            }
        }
        .onChange(of: inputMode) { _, newValue in
            questionModes[currentQuestion.id] = newValue
        }
    }

    private var topBar: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(Color.ink900)
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Close practise session")
            .accessibilityHint("Returns to the question bank")

            Spacer()

            Text("Practise Session")
                .font(.headline.weight(.semibold))
                .foregroundStyle(Color.ink900)

            Spacer()

            Button {
                endSession()
            } label: {
                Text("End")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.ink600)
                    .frame(minWidth: 44, minHeight: 36, alignment: .trailing)
            }
            .buttonStyle(.plain)
            .accessibilityHint("Ends the session and shows your summary")
        }
    }

    private var questionMeta: some View {
        HStack(alignment: .lastTextBaseline) {
            Text("Question \(currentIndex + 1) of \(totalQuestions)")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.ink600)

            Spacer()

            Button {
                showTips.toggle()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "lightbulb.fill")
                    Text("Tips")
                        .font(.subheadline.weight(.semibold))
                }
                .foregroundStyle(showTips ? Color.sage500 : Color.ink500)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(showTips ? Color.sage100 : Color.surfaceWhite)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color.ink200, lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Question progress")
        .accessibilityValue("Question \(currentIndex + 1) of \(totalQuestions)")
    }

    private var progressBar: some View {
        ProgressView(value: progressValue)
            .progressViewStyle(.linear)
            .tint(Color.sage500)
            .scaleEffect(x: 1, y: 1.4, anchor: .center)
            .accessibilityLabel("Session progress")
            .accessibilityValue("Question \(currentIndex + 1) of \(totalQuestions)")
    }

    private var questionCard: some View {
        CardContainer(backgroundColor: Color.surfaceWhite, cornerRadius: 24, showShadow: false) {
            VStack(alignment: .center, spacing: 18) {
                Chip(title: currentQuestion.category.title, isSelected: true)

                Text(currentQuestion.text)
                    .font(.title2.weight(.bold))
                    .foregroundStyle(Color.ink900)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
                    .minimumScaleFactor(0.85)
                    .padding(.horizontal, 8)

                HStack(spacing: 16) {
                    TimerBlock(value: String(format: "%02d", minutes), label: "MIN")
                    Text(":")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(Color.ink500)
                    TimerBlock(value: String(format: "%02d", seconds), label: "SEC")
                }
            }
            .frame(maxWidth: .infinity, alignment: .center)
        }
    }

    private var tipsPanel: some View {
        Group {
            if showTips {
                let tips = DrillTipsEngine().tips(for: responseText)
                CardContainer(backgroundColor: Color.surfaceWhite, cornerRadius: 18, showShadow: false) {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Quick tips")
                            .font(.headline)
                            .foregroundStyle(Color.ink900)

                        if tips.isEmpty {
                            Text("No tips right now — keep going.")
                                .font(.subheadline)
                                .foregroundStyle(Color.ink500)
                        } else {
                            ForEach(tips, id: \.self) { tip in
                                HStack(alignment: .top, spacing: 8) {
                                    Image(systemName: "sparkles")
                                        .foregroundStyle(Color.sage500)
                                    Text(tip)
                                        .font(.subheadline)
                                        .foregroundStyle(Color.ink700)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    private var inputModeToggle: some View {
        HStack(spacing: 8) {
            segmentButton(title: "Speak", systemImage: "mic.fill", mode: .speak)
            segmentButton(title: "Write", systemImage: "pencil", mode: .write)
        }
        .padding(6)
        .background(Color.surfaceWhite)
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .stroke(Color.ink200, lineWidth: 1)
        )
    }

    private func segmentButton(title: String, systemImage: String, mode: InputMode) -> some View {
        let isActive = inputMode == mode
        return Button {
            inputMode = mode
        } label: {
            HStack(spacing: 8) {
                Image(systemName: systemImage)
                Text(title)
                    .fontWeight(.semibold)
            }
            .foregroundStyle(isActive ? Color.sage500 : Color.ink600)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(isActive ? Color.sage100 : Color.clear)
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
        .accessibilityValue(isActive ? "Selected" : "Not selected")
    }

    private var inputArea: some View {
        Group {
            switch inputMode {
            case .speak:
                VStack(spacing: 16) {
                    WaveformView()
                        .frame(height: 60)

                    DictationButton(text: $responseText)
                        .disabled(isPaused)

                    if isPaused {
                        Text("Paused")
                            .font(.subheadline)
                            .foregroundStyle(Color.ink500)
                    } else {
                        Text("Tap the mic to record your answer.")
                            .font(.subheadline)
                            .foregroundStyle(Color.ink500)
                    }

                    ZStack(alignment: .topLeading) {
                        if responseText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            Text("Transcript will appear here.")
                                .font(.subheadline)
                                .foregroundStyle(Color.ink400)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 14)
                                .allowsHitTesting(false)
                        }

                        TextEditor(text: $responseText)
                            .font(.body)
                            .foregroundStyle(Color.ink900)
                            .scrollContentBackground(.hidden)
                            .padding(12)
                            .frame(minHeight: 140)
                            .disabled(isPaused)
                    }
                    .background(Color.surfaceWhite)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(Color.ink200, lineWidth: 1)
                    )
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            case .write:
                TextEditor(text: $responseText)
                    .frame(minHeight: 140)
                    .padding(12)
                    .background(Color.surfaceWhite)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(Color.ink200, lineWidth: 1)
                    )
                    .disabled(isPaused)
            }
        }
    }

    private var linkedStoryCard: some View {
        Button {
            showStoryPicker = true
        } label: {
            CardContainer(backgroundColor: Color.surfaceWhite, cornerRadius: 18, showShadow: false) {
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(Color.sage100)
                            .frame(width: 40, height: 40)

                        Image(systemName: "link")
                            .foregroundStyle(Color.sage500)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Linked Story")
                            .font(.caption)
                            .foregroundStyle(Color.ink500)

                        Text(linkedStoryTitle)
                            .font(.headline)
                            .foregroundStyle(Color.ink900)
                            .lineLimit(1)
                            .minimumScaleFactor(0.85)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .foregroundStyle(Color.ink400)
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Linked story")
        .accessibilityValue(linkedStoryTitle)
        .accessibilityHint("Opens story picker")
    }

    private var linkedStoryTitle: String {
        if let story = linkedStoryByQuestionId[currentQuestion.id] {
            return story.title
        }
        return stories.isEmpty ? "No stories yet" : "Link a Story"
    }

    private var actionBar: some View {
        VStack(spacing: 12) {
            if savedQuestionId == currentQuestion.id {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Color.sage500)

                    Text("Saved to your history.")
                        .font(.subheadline)
                        .foregroundStyle(Color.ink700)

                    Spacer()

                    Button("Edit saved answer") {
                        if let attempt = lastSavedAttemptByQuestionId[currentQuestion.id] {
                            selectedAttempt = attempt
                        }
                    }
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.sage500)
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 20)
            }

            HStack(spacing: 12) {
                controlButton(
                    title: "Previous",
                    systemImage: "chevron.left"
                ) {
                    goToPreviousQuestion()
                }
                .disabled(currentIndex == 0)
                .opacity(currentIndex == 0 ? 0.5 : 1)

                controlButton(
                    title: isPaused ? "Play" : "Pause",
                    systemImage: isPaused ? "play.fill" : "pause.fill"
                ) {
                    togglePause()
                }

                controlButton(
                    title: currentIndex >= questions.count - 1 ? "Finish" : "Next",
                    systemImage: currentIndex >= questions.count - 1 ? "checkmark.circle" : "chevron.right"
                ) {
                    if currentIndex >= questions.count - 1 {
                        endSession()
                    } else {
                        goToNextQuestion()
                    }
                }
            }
            .padding(.horizontal, 20)

            HStack(spacing: 12) {
                SecondaryActionButton(title: "Start again") {
                    startAgain()
                }

                PrimaryCTAButton(title: "Save answer", systemImage: "tray.and.arrow.down") {
                    saveCurrentAnswer()
                }
                .disabled(currentAnswerTrimmed.isEmpty)
                .opacity(currentAnswerTrimmed.isEmpty ? 0.6 : 1)
            }
            .padding(.horizontal, 20)

            if !purchaseManager.isPro {
                Text(ProGate.unlimitedAnswers.inlineMessage)
                    .font(.footnote)
                    .foregroundStyle(Color.ink500)
                    .padding(.horizontal, 20)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(.top, 8)
        .padding(.bottom, 12)
        .background(Color.cream50)
        .overlay(
            Divider()
                .opacity(0.4),
            alignment: .top
        )
    }

    private func controlButton(title: String, systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: systemImage)
                    .font(.subheadline.weight(.semibold))
                Text(title)
                    .font(.subheadline.weight(.semibold))
            }
            .foregroundStyle(Color.ink700)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity)
            .background(Color.surfaceWhite)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(Color.ink200, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private var currentAnswerTrimmed: String {
        responseText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func recordCurrentQuestion() {
        let currentId = currentQuestion.id
        guard !completedQuestions.contains(where: { $0.id == currentId }) else { return }
        completedQuestions.append(currentQuestion)
        questionModes[currentId] = inputMode

        let trimmed = draftsByQuestionId[currentId]?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if !trimmed.isEmpty {
            draftsByQuestionId[currentId] = trimmed
        }
    }

    private func endSession() {
        recordCurrentQuestion()
        let endDate = Date()
        summaryDurationSeconds = max(Int(endDate.timeIntervalSince(sessionStart)), 0)
        summaryAttempts = buildSummaryAttempts(timestamp: endDate)
        AnalyticsEventLogger.shared.log(.drillCompleted)
        showSummary = true
    }

    private func buildSummaryAttempts(timestamp: Date) -> [Attempt] {
        let duration = minutes * 60 + seconds
        return completedQuestions.map { question in
            Attempt(
                timestamp: timestamp,
                durationSeconds: duration,
                mode: questionModes[question.id]?.attemptMode ?? .speak,
                questionId: question.id,
                questionText: question.text,
                category: question.category.title,
                linkedStoryId: linkedStoryByQuestionId[question.id]?.id,
                notes: draftsByQuestionId[question.id],
                rating: nil
            )
        }
    }

    private func resetSession() {
        currentIndex = 0
        inputMode = .speak
        isPaused = false
        responseText = ""
        minutes = 1
        seconds = 45
        sessionStart = Date()
        completedQuestions = []
        questionModes = [:]
        draftsByQuestionId = [:]
        linkedStoryByQuestionId = [:]
        summaryAttempts = []
        summaryDurationSeconds = 0
        showSummary = false
        savedAttempts = []
        savedQuestionId = nil
        lastSavedAttemptByQuestionId = [:]
    }

    private func dismissToQuestionBank() {
        dismiss()
    }

    private func goToPreviousQuestion() {
        storeCurrentDraft()
        guard currentIndex > 0 else { return }
        currentIndex -= 1
        isPaused = false
    }

    private func goToNextQuestion() {
        storeCurrentDraft()
        guard currentIndex + 1 < questions.count else { return }
        currentIndex += 1
        isPaused = false
    }

    private func storeCurrentDraft() {
        draftsByQuestionId[currentQuestion.id] = responseText
        questionModes[currentQuestion.id] = inputMode
    }

    private func loadDraftForCurrentQuestion() {
        responseText = draftsByQuestionId[currentQuestion.id] ?? ""
        if let mode = questionModes[currentQuestion.id] {
            inputMode = mode
        }
    }

    private func saveCurrentAnswer() {
        let trimmed = currentAnswerTrimmed
        guard !trimmed.isEmpty else { return }

        enforceAnswerLimitIfNeeded()

        let attempt = PracticeAttempt(
            source: "drill",
            questionTextSnapshot: currentQuestion.text,
            questionId: currentQuestion.id,
            durationSeconds: minutes * 60 + seconds,
            notes: trimmed,
            audioPath: nil
        )

        modelContext.insert(attempt)
        try? modelContext.save()

        draftsByQuestionId[currentQuestion.id] = trimmed
        savedQuestionId = currentQuestion.id

        if let previous = lastSavedAttemptByQuestionId[currentQuestion.id] {
            savedAttempts.removeAll { $0.id == previous.id }
        }
        savedAttempts.append(attempt)
        lastSavedAttemptByQuestionId[currentQuestion.id] = attempt
        AnalyticsEventLogger.shared.log(.drillQuestionSaved)
    }

    private func enforceAnswerLimitIfNeeded() {
        guard !purchaseManager.isPro else { return }
        let predicate = #Predicate<PracticeAttempt> {
            $0.questionId == currentQuestion.id || $0.questionTextSnapshot == currentQuestion.text
        }
        let descriptor = FetchDescriptor<PracticeAttempt>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.createdAt, order: .forward)]
        )
        if let existing = try? modelContext.fetch(descriptor), existing.count >= freeAnswerLimitPerQuestion {
            let overflow = existing.count - (freeAnswerLimitPerQuestion - 1)
            let toDelete = existing.prefix(max(overflow, 0))
            toDelete.forEach { modelContext.delete($0) }
        }
    }

    private func startAgain() {
        responseText = ""
        draftsByQuestionId[currentQuestion.id] = ""
        savedQuestionId = nil
    }

    private func togglePause() {
        isPaused.toggle()
    }
}

private enum InputMode {
    case speak
    case write

    var attemptMode: AttemptMode {
        switch self {
        case .speak:
            return .speak
        case .write:
            return .write
        }
    }
}

private struct TimerBlock: View {
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 6) {
            Text(value)
                .font(.title2.weight(.bold))
                .foregroundStyle(Color.sage500)
                .frame(width: 64, height: 52)
                .background(Color.sage100)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

            Text(label)
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.ink500)
        }
    }
}

private struct WaveformView: View {
    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<7, id: \.self) { index in
                Capsule()
                    .fill(index == 3 ? Color.sage500 : Color.sage500.opacity(0.6))
                    .frame(width: 8, height: index == 3 ? 46 : 30)
            }
        }
    }
}

private struct SecondaryActionButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.weight(.semibold))
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
}

private struct StoryPickerSheet: View {
    let stories: [Story]
    let selectedStoryId: UUID?
    let onSelect: (Story) -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                if stories.isEmpty {
                    ContentUnavailableView("No stories yet", systemImage: "book")
                } else {
                    ForEach(stories) { story in
                        Button {
                            onSelect(story)
                        } label: {
                            HStack(spacing: 12) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(story.title)
                                        .font(.headline)
                                        .foregroundStyle(Color.ink900)

                                    Text(story.category)
                                        .font(.caption)
                                        .foregroundStyle(Color.ink500)
                                }

                                Spacer()

                                if selectedStoryId == story.id {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(Color.sage500)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .navigationTitle("Link Story")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

extension QuestionBankItem {
    static var placeholder: QuestionBankItem {
        QuestionBankItem(
            id: UUID(),
            text: "Describe a situation where you had to handle a difficult client.",
            category: .behavioral,
            isCustom: false
        )
    }
}
