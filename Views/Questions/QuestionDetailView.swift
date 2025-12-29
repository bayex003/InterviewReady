// Testing Checklist:
// - Manual: open question, type something, go back → attempt added
// - Manual: open question, do nothing, go back → no attempt
// - Drill: stop recording on a question → drill attempt added
// - Attempt history: saved answers show newest first with editable detail view
// - App compiles and runs

import SwiftUI
import SwiftData

struct QuestionDetailView: View {
    @Bindable var question: Question

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var purchaseManager: PurchaseManager

    @Query(sort: \PracticeAttempt.createdAt, order: .reverse) private var allAttempts: [PracticeAttempt]
    @Query private var storyLinks: [QuestionStoryLink]

    @State private var showTip = false
    @State private var showExample = false
    @State private var didEditThisSession = false
    @State private var showDeleteConfirmation = false
    @State private var showPracticeSession = false
    @State private var activeSheet: ActiveSheet?
    @State private var selectedAnswerFilter: AnswerFilter = .all

    private let categories = ["General", "Basics", "Behavioural", "Technical", "Strengths", "Weaknesses"]
    private let freeAnswerLimitPerQuestion = 3

    enum ActiveSheet: Identifiable {
        case paywall
        case storyPicker

        var id: String {
            switch self {
            case .paywall: return "paywall"
            case .storyPicker: return "storyPicker"
            }
        }
    }

    private var proGate: ProGatekeeper {
        ProGatekeeper(isPro: { purchaseManager.isPro }, presentPaywall: { activeSheet = .paywall })
    }

    private var canEditCustomQuestion: Bool {
        question.isCustom
    }

    private var questionTextBinding: Binding<String> {
        Binding(
            get: { question.text },
            set: { newValue in
                question.text = newValue
                question.updatedAt = Date()
            }
        )
    }

    private var tipBinding: Binding<String> {
        Binding(
            get: { question.tip ?? "" },
            set: { newValue in
                question.tip = newValue
                question.updatedAt = Date()
            }
        )
    }

    private var exampleAnswerBinding: Binding<String> {
        Binding(
            get: { question.exampleAnswer ?? "" },
            set: { newValue in
                question.exampleAnswer = newValue
                question.updatedAt = Date()
            }
        )
    }

    private var savedAttemptsForQuestion: [PracticeAttempt] {
        let attemptsForQuestion = allAttempts.filter {
            ($0.questionId == question.id) || ($0.questionTextSnapshot == question.text)
        }
        return attemptsForQuestion.filter {
            let hasText = ($0.notes ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
            return hasText || $0.audioPath != nil
        }
    }

    private var hasAudioAnswers: Bool {
        savedAttemptsForQuestion.contains { $0.audioPath != nil }
    }

    private var linkedStoryCount: Int {
        storyLinks.count
    }

    init(question: Question) {
        self.question = question
        _storyLinks = Query(filter: #Predicate<QuestionStoryLink> { $0.questionId == question.id })
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {

                // Question Header Card
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "bubble.left.and.bubble.right.fill")
                            .foregroundStyle(Color.sage500)

                        if canEditCustomQuestion {
                            Menu {
                                ForEach(categories, id: \.self) { category in
                                    Button(category) {
                                        question.category = category
                                        question.updatedAt = Date()
                                    }
                                }
                            } label: {
                                HStack(spacing: 6) {
                                    Text(question.category.uppercased())
                                        .font(.caption)
                                        .fontWeight(.bold)
                                        .foregroundStyle(Color.sage500)
                                    Image(systemName: "chevron.down")
                                        .font(.caption2)
                                        .foregroundStyle(Color.sage500)
                                }
                            }
                        } else {
                            Text(question.category.uppercased())
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundStyle(Color.sage500)
                        }

                        Spacer()
                    }

                    if canEditCustomQuestion {
                        TextEditor(text: questionTextBinding)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundStyle(Color.ink900)
                            .scrollContentBackground(.hidden)
                            .frame(minHeight: 90)
                    } else {
                        Text(question.text)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundStyle(Color.ink900)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding(20)
                .background(Color.surfaceWhite)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)

                PrimaryCTAButton(title: "Practise this question", systemImage: "play.fill") {
                    AnalyticsEventLogger.shared.log(.questionPractiseTapped)
                    AnalyticsEventLogger.shared.log(.drillStartedSelected)
                    showPracticeSession = true
                }

                storyLinksSection

                savedAnswersSection

                // Tip
                DisclosureCard(
                    title: "Tip",
                    systemImage: "lightbulb",
                    isExpanded: $showTip
                ) {
                    if canEditCustomQuestion {
                        TextEditor(text: tipBinding)
                            .font(.body)
                            .foregroundStyle(Color.ink900)
                            .scrollContentBackground(.hidden)
                            .frame(minHeight: 120)
                    } else {
                        let tipText = (question.tip ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
                        if tipText.isEmpty {
                            Text("No tip available yet.")
                                .font(.body)
                                .foregroundStyle(Color.ink600)
                        } else {
                            Text(tipText)
                                .font(.body)
                                .foregroundStyle(Color.ink900)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }

                // Example answer
                DisclosureCard(
                    title: "Example answer",
                    systemImage: "doc.text",
                    isExpanded: $showExample
                ) {
                    if canEditCustomQuestion {
                        TextEditor(text: exampleAnswerBinding)
                            .font(.body)
                            .foregroundStyle(Color.ink900)
                            .scrollContentBackground(.hidden)
                            .frame(minHeight: 140)
                    } else {
                        let exampleText = (question.exampleAnswer ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
                        if exampleText.isEmpty {
                            Text("No example answer available yet.")
                                .font(.body)
                                .foregroundStyle(Color.ink600)
                        } else {
                            Text(exampleText)
                                .font(.body)
                                .foregroundStyle(Color.ink900)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }

                // Your Answer input
                VStack(alignment: .leading, spacing: 8) {
                    Text("YOUR ANSWER")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundStyle(Color.ink600)
                        .padding(.leading, 4)

                    ZStack(alignment: .topLeading) {
                        if question.answerText.isEmpty {
                            Text("Tap here to type your full answer…")
                                .font(.body)
                                .foregroundStyle(Color.ink400)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 16)
                                .allowsHitTesting(false)
                        }

                        TextEditor(text: $question.answerText)
                            .font(.body)
                            .foregroundStyle(Color.ink900)
                            .scrollContentBackground(.hidden)
                            .padding(12)
                            .frame(minHeight: 400)
                    }
                    .background(Color.surfaceWhite)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(Color.ink200, lineWidth: 1)
                    )
                }

                if canEditCustomQuestion {
                    Button(role: .destructive) {
                        showDeleteConfirmation = true
                    } label: {
                        Text("Delete Question")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .overlay(
                                Capsule()
                                    .strokeBorder(Color.red.opacity(0.6), lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                }

                Spacer(minLength: 60)
            }
            .padding()
        }
        .background(Color.cream50)
        .tapToDismissKeyboard()
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: question.answerText) { _, _ in
            didEditThisSession = true
        }
        // TO →
        .onDisappear {
            // Keep SwiftData mutations on the main actor; avoid transient invalid state during dismiss/navigation.
            Task { @MainActor in
                let trimmed = question.answerText.trimmingCharacters(in: .whitespacesAndNewlines)

                if !trimmed.isEmpty, didEditThisSession {
                    question.dateAnswered = Date()
                    question.isAnswered = true

                    enforceAnswerLimitIfNeeded()

                    let attempt = PracticeAttempt(
                        source: "manual",
                        questionTextSnapshot: question.text,
                        questionId: question.id,
                        notes: trimmed,
                        audioPath: nil
                    )
                    modelContext.insert(attempt)
                    try? modelContext.save()
                } else if trimmed.isEmpty {
                    question.isAnswered = false
                    try? modelContext.save()
                }
            }
        }
        .alert("Delete this question?", isPresented: $showDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                deleteQuestion()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will remove your custom question permanently.")
        }
        .sheet(isPresented: $showPracticeSession) {
            PracticeSessionView(questions: [QuestionBankItem(question)])
        }
        .sheet(item: $activeSheet) { sheet in
            switch sheet {
            case .paywall:
                PaywallView()
                    .environmentObject(purchaseManager)
            case .storyPicker:
                StoryLinkPickerView(initialSelection: linkedStoryIds) { selection in
                    updateStoryLinks(selection)
                }
            }
        }
        .onChange(of: hasAudioAnswers) { _, newValue in
            if !newValue {
                selectedAnswerFilter = .all
            }
        }
    }

    private func deleteQuestion() {
        modelContext.delete(question)
        try? modelContext.save()
        dismiss()
    }

    // TO →
    private func enforceAnswerLimitIfNeeded() {
        guard !purchaseManager.isPro else { return }

        // ✅ Capture values as constants so #Predicate doesn't try to treat `question` as a keypath source.
        let qid = question.id
        let qtext = question.text

        let predicate = #Predicate<PracticeAttempt> {
            ($0.questionId == qid) || ($0.questionTextSnapshot == qtext)
        }

        let descriptor = FetchDescriptor<PracticeAttempt>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.createdAt, order: .forward)]
        )

        if let existing = try? modelContext.fetch(descriptor), existing.count >= freeAnswerLimitPerQuestion {
            let overflow = existing.count - (freeAnswerLimitPerQuestion - 1)
            let toDelete = existing.prefix(max(overflow, 0))
            toDelete.forEach { modelContext.delete($0) }
            try? modelContext.save()
        }
    }

    private var savedAnswersSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("SAVED ANSWERS")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundStyle(Color.ink600)
                .padding(.leading, 4)

            let filteredAttempts = savedAttemptsForQuestion.filter { attempt in
                switch selectedAnswerFilter {
                case .all:
                    return true
                case .audioOnly:
                    return attempt.audioPath != nil
                }
            }

            if hasAudioAnswers {
                Picker("Answer filter", selection: $selectedAnswerFilter) {
                    ForEach(AnswerFilter.allCases) { filter in
                        Text(filter.title).tag(filter)
                    }
                }
                .pickerStyle(.segmented)
            }

            if savedAttemptsForQuestion.isEmpty {
                EmptyStateCard(
                    title: "No saved answers yet",
                    message: "Your saved answers for this question will appear here after you practise or type an answer."
                )
            } else {
                VStack(spacing: 12) {
                    if filteredAttempts.isEmpty {
                        CardContainer(showShadow: false) {
                            Text("No audio answers yet.")
                                .font(.subheadline)
                                .foregroundStyle(Color.ink500)
                        }
                    } else {
                        ForEach(filteredAttempts, id: \.id) { attempt in
                            NavigationLink {
                                AnswerDetailView(attempt: attempt)
                            } label: {
                                savedAnswerRow(attempt)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }

            if !purchaseManager.isPro {
                Text(ProGate.unlimitedAnswers.inlineMessage)
                    .font(.footnote)
                    .foregroundStyle(Color.ink500)
            }
        }
    }

    private var storyLinksSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("STORIES")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundStyle(Color.ink600)
                .padding(.leading, 4)

            CardContainer(showShadow: false) {
                VStack(spacing: 12) {
                    Button {
                        handleLinkStoryTapped()
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "link")
                                .foregroundStyle(Color.sage500)
                            Text("Link story")
                                .font(.headline)
                                .foregroundStyle(Color.ink900)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(Color.ink400)
                        }
                        .padding(.vertical, 4)
                    }
                    .buttonStyle(.plain)

                    if linkedStoryCount > 0 {
                        Divider().opacity(0.6)

                        NavigationLink {
                            LinkedStoriesView(questionId: question.id)
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "book")
                                    .foregroundStyle(Color.ink500)
                                Text("View linked stories")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(Color.ink700)
                                Spacer()
                                Text("\(linkedStoryCount)")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(Color.ink400)
                            }
                            .padding(.vertical, 4)
                        }
                        .buttonStyle(.plain)
                    }

                    if !purchaseManager.isPro {
                        Text(ProGate.storyLinking.inlineMessage)
                            .font(.footnote)
                            .foregroundStyle(Color.ink500)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
        }
    }

    private var linkedStoryIds: Set<UUID> {
        Set(storyLinks.map(\.storyId))
    }

    private func handleLinkStoryTapped() {
        proGate.requirePro(.storyLinking) {
            activeSheet = .storyPicker
        }
    }

    private func updateStoryLinks(_ selection: Set<UUID>) {
        let existingIds = linkedStoryIds
        let toRemove = storyLinks.filter { !selection.contains($0.storyId) }
        toRemove.forEach { modelContext.delete($0) }

        let toAdd = selection.subtracting(existingIds)
        toAdd.forEach { storyId in
            let link = QuestionStoryLink(questionId: question.id, storyId: storyId)
            modelContext.insert(link)
        }

        try? modelContext.save()
    }

    private func savedAnswerRow(_ attempt: PracticeAttempt) -> some View {
        CardContainer(showShadow: false) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(DateFormatters.mediumDate.string(from: attempt.createdAt))
                        .font(.caption)
                        .foregroundStyle(Color.ink500)

                    Spacer()

                    if attempt.audioPath != nil {
                        Image(systemName: "play.circle.fill")
                            .foregroundStyle(Color.sage500)
                    }
                }

                Text(answerPreview(for: attempt))
                    .font(.subheadline)
                    .foregroundStyle(Color.ink900)
                    .lineLimit(2)
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

private struct DisclosureCard<Content: View>: View {
    let title: String
    let systemImage: String
    @Binding var isExpanded: Bool
    @ViewBuilder var content: () -> Content

    // A smoother, less "jumpy" transition for variable-height content
    private var contentTransition: AnyTransition {
        .asymmetric(
            insertion: .opacity.combined(with: .scale(scale: 0.98, anchor: .top)),
            removal: .opacity
        )
    }

    var body: some View {
        VStack(spacing: 0) {
            Button {
                // Let the .animation(value:) drive the entire transition smoothly
                isExpanded.toggle()
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: systemImage)
                        .foregroundStyle(Color.ink600)

                    Text(title)
                        .font(.headline)
                        .foregroundStyle(Color.ink900)

                    Spacer()

                    Image(systemName: "chevron.down")
                        .foregroundStyle(Color.ink400)
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                }
                .padding(16)
                .contentShape(Rectangle()) // bigger tap target = feels smoother
            }
            .buttonStyle(.plain)

            if isExpanded {
                Divider().opacity(0.6)

                VStack(alignment: .leading, spacing: 10) {
                    content()
                }
                .padding(16)
                .transition(contentTransition)
            }
        }
        .background(Color.surfaceWhite)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
        // ✅ This is the key: animate the whole card’s layout changes
        .animation(.snappy(duration: 0.28), value: isExpanded)
    }
}

private enum AnswerFilter: String, CaseIterable, Identifiable {
    case all = "All answers"
    case audioOnly = "Audio only"

    var id: String { rawValue }

    var title: String { rawValue }
}
