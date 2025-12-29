import SwiftUI
import SwiftData

struct QuestionsListView: View {
    @EnvironmentObject private var attemptsStore: AttemptsStore
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Question.updatedAt, order: .reverse) private var questions: [Question]

    @State private var searchText: String = ""
    @State private var selectedFilter: CategoryFilter = .all

    @State private var isSelecting: Bool = false
    @State private var selectedQuestionIDs: Set<UUID> = []

    @State private var showSession: Bool = false
    @State private var sessionQuestions: [QuestionBankItem] = []
    @State private var showAddQuestion = false

    private let showsSelectionToggle: Bool

    init(initialSelectionMode: Bool = false, showsSelectionToggle: Bool = true) {
        self.showsSelectionToggle = showsSelectionToggle
        _isSelecting = State(initialValue: initialSelectionMode)
    }

    private var filteredQuestions: [Question] {
        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)

        return questions.filter { q in
            guard selectedFilter.matches(q) else { return false }
            if trimmed.isEmpty { return true }
            return "\(q.text) \(q.category)".localizedCaseInsensitiveContains(trimmed)
        }
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Color.cream50.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {
                    titleRow

                    attemptsShortcut

                    searchRow

                    filterRow

                    questionsSection
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, isSelecting ? 120 : 24)
            }

            if isSelecting {
                startSessionBar
                    .frame(maxWidth: .infinity)
            }

            FloatingAddButton {
                showAddQuestion = true
            }
            .floatingAddButtonPosition()
            .padding(.bottom, isSelecting ? 88 : 0)
        }
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showSession) {
            PracticeSessionView(questions: sessionQuestions)
        }
        .sheet(isPresented: $showAddQuestion) {
            AddQuestionView()
        }
    }

    // MARK: - Title Row

    private var titleRow: some View {
        HStack(alignment: .center) {
            Text("Question Bank")
                .font(.largeTitle.bold())
                .foregroundStyle(Color.ink900)

            Spacer()

            HStack(spacing: 12) {
                Button {
                    showAddQuestion = true
                } label: {
                    Image(systemName: "plus")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(Color.ink900)
                        .frame(width: 44, height: 44)
                        .background(Color.surfaceWhite)
                        .clipShape(Circle())
                        .overlay(
                            Circle().stroke(Color.ink200, lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Add question")

                if showsSelectionToggle {
                    Button(isSelecting ? "Done" : "Select") {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            isSelecting.toggle()
                            if !isSelecting { selectedQuestionIDs.removeAll() }
                        }
                    }
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.sage500)
                }
            }
        }
    }

    // MARK: - Attempts Shortcut

    private var attemptsShortcut: some View {
        NavigationLink {
            AttemptsListView(attemptsStore: attemptsStore)
        } label: {
            CardContainer(showShadow: false) {
                HStack(spacing: 12) {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.sage100)
                        .frame(width: 44, height: 44)
                        .overlay(
                            Image(systemName: "clock.arrow.circlepath")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundStyle(Color.sage500)
                        )

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Attempts")
                            .font(.headline)
                            .foregroundStyle(Color.ink900)

                        Text("\(attemptsStore.attempts.count) saved in your history")
                            .font(.caption)
                            .foregroundStyle(Color.ink500)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .foregroundStyle(Color.ink400)
                }
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Search

    private var searchRow: some View {
        CardContainer(showShadow: false) {
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(Color.ink400)

                TextField("Search questions or tags…", text: $searchText)
                    .font(.subheadline)
                    .foregroundStyle(Color.ink900)

                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(Color.ink300)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Filters

    private var filterRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(CategoryFilter.allCases) { filter in
                    TagChip(title: filter.title, isSelected: filter == selectedFilter) {
                        selectedFilter = filter
                    }
                }
            }
            .padding(.vertical, 2)
        }
    }

    // MARK: - List

    private var questionsSection: some View {
        VStack(spacing: 12) {
            if questions.isEmpty {
                // TO →
                EmptyStateCard(
                    systemImage: "text.bubble",
                    title: "Build your question bank",
                    subtitle: "Add custom questions to practise with anytime.",
                    ctaTitle: "Add a question"
                )
                .contentShape(Rectangle())
                .onTapGesture { showAddQuestion = true }
                .accessibilityAddTraits(.isButton)
            } else if filteredQuestions.isEmpty {
                CardContainer(showShadow: false) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("No questions found")
                            .font(.headline)
                            .foregroundStyle(Color.ink900)

                        Text("Try a different search or category.")
                            .font(.subheadline)
                            .foregroundStyle(Color.ink500)
                    }
                }
            } else {
                ForEach(filteredQuestions) { q in
                    if isSelecting {
                        QuestionRowView(
                            question: q,
                            isSelecting: isSelecting,
                            isSelected: selectedQuestionIDs.contains(q.id)
                        ) {
                            toggleSelection(for: q)
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            if q.isCustom && !isSelecting {
                                Button(role: .destructive) {
                                    delete(question: q)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    } else {
                        NavigationLink {
                            QuestionDetailView(question: q)
                        } label: {
                            QuestionRowView(
                                question: q,
                                isSelecting: false,
                                isSelected: false,
                                onTap: {}
                            )
                        }
                        .buttonStyle(.plain)
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            if q.isCustom {
                                Button(role: .destructive) {
                                    delete(question: q)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    private func toggleSelection(for q: Question) {
        guard isSelecting else { return }
        if selectedQuestionIDs.contains(q.id) {
            selectedQuestionIDs.remove(q.id)
        } else {
            selectedQuestionIDs.insert(q.id)
        }
    }

    private func delete(question: Question) {
        modelContext.delete(question)
        try? modelContext.save()
    }

    // MARK: - Bottom Start Bar

    private var startSessionBar: some View {
        VStack(spacing: 10) {
            Divider().opacity(0.4)

            let buttonTitle = selectedQuestionIDs.isEmpty
                ? "Start drill"
                : "Start drill (\(selectedQuestionIDs.count))"

            PrimaryCTAButton(buttonTitle) {
                let selected = filteredQuestions.filter { selectedQuestionIDs.contains($0.id) }
                sessionQuestions = selected.map { QuestionBankItem($0) }
                AnalyticsEventLogger.shared.log(.drillStartedSelected)
                showSession = true
            }
            .opacity(selectedQuestionIDs.isEmpty ? 0.5 : 1)
            .disabled(selectedQuestionIDs.isEmpty)
            .padding(.horizontal, 20)
            .padding(.bottom, 12)
        }
        .background(Color.cream50)
    }

    // MARK: - Nested Types (prevents redeclaration)

    private enum CategoryFilter: String, CaseIterable, Identifiable {
        case all
        case behavioural
        case technical
        case leadership

        var id: String { rawValue }

        var title: String {
            switch self {
            case .all: return "All"
            case .behavioural: return "Behavioural"
            case .technical: return "Technical"
            case .leadership: return "Leadership"
            }
        }

        func matches(_ q: Question) -> Bool {
            switch self {
            case .all:
                return true
            case .behavioural:
                return q.category.localizedCaseInsensitiveContains("behav")
            case .technical:
                return q.category.localizedCaseInsensitiveContains("tech")
            case .leadership:
                return q.category.localizedCaseInsensitiveContains("lead")
            }
        }
    }

    private struct QuestionRowView: View {
        let question: Question
        let isSelecting: Bool
        let isSelected: Bool
        let onTap: () -> Void

        @Query private var links: [QuestionStoryLink]

        private let selectionIndicatorWidth: CGFloat = 32

        init(
            question: Question,
            isSelecting: Bool,
            isSelected: Bool,
            onTap: @escaping () -> Void
        ) {
            self.question = question
            self.isSelecting = isSelecting
            self.isSelected = isSelected
            self.onTap = onTap
            _links = Query(filter: #Predicate<QuestionStoryLink> { $0.questionId == question.id })
        }

        var body: some View {
            CardContainer(showShadow: false) {
                HStack(alignment: .top, spacing: 12) {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.sage100)
                        .frame(width: 44, height: 44)
                        .overlay(
                            Image(systemName: "text.bubble")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundStyle(Color.sage500)
                        )

                    VStack(alignment: .leading, spacing: 8) {
                        Text(question.text)
                            .font(.headline)
                            .foregroundStyle(Color.ink900)
                            .lineLimit(2)

                        HStack(spacing: 8) {
                            TagChip(title: question.category, isSelected: true)
                            Text("Unanswered")
                                .font(.caption)
                                .foregroundStyle(Color.ink500)
                        }

                        if links.count > 0 {
                            Text("🔗 \(links.count) \(links.count == 1 ? "Story" : "Stories") Linked")
                                .font(.caption)
                                .foregroundStyle(Color.ink500)
                        }
                    }

                    Spacer()

                    Image(systemName: isSelected ? "checkmark.square.fill" : "square")
                        .foregroundStyle(isSelected ? Color.sage500 : Color.ink300)
                        .font(.system(size: 18, weight: .semibold))
                        .padding(.top, 6)
                        .opacity(isSelecting ? 1 : 0)
                        .accessibilityHidden(!isSelecting)
                        .frame(width: selectionIndicatorWidth, alignment: .trailing)
                }
            }
            .onTapGesture {
                if isSelecting { onTap() }
            }
        }
    }

    private struct TagChip: View {
        let title: String
        var isSelected: Bool = false
        var action: (() -> Void)? = nil

        private var foregroundColor: Color {
            TagColorResolver.color(forTag: title)
        }

        private var backgroundColor: Color {
            TagColorResolver.background(forTag: title)
        }

        var body: some View {
            Group {
                if let action {
                    Button(action: action) { chipBody }
                        .buttonStyle(.plain)
                } else {
                    chipBody
                }
            }
        }

        private var chipBody: some View {
            Text(title)
                .font(.caption.weight(.semibold))
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .foregroundStyle(isSelected ? foregroundColor : foregroundColor.opacity(0.75))
                .background(
                    Capsule()
                        .fill(isSelected ? backgroundColor : backgroundColor.opacity(0.5))
                )
                .overlay(
                    Capsule()
                        .stroke(foregroundColor.opacity(isSelected ? 0.3 : 0.2), lineWidth: 1)
                )
        }
    }
}
