import SwiftUI
import SwiftData

struct QuestionsListView: View {
    @EnvironmentObject private var attemptsStore: AttemptsStore
    @Query(sort: \Question.updatedAt, order: .reverse) private var questions: [Question]

    @State private var searchText: String = ""
    @State private var selectedFilter: CategoryFilter = .all

    @State private var isSelecting: Bool = false
    @State private var selectedQuestionIDs: Set<UUID> = []

    @State private var showSession: Bool = false
    @State private var sessionQuestions: [QuestionBankItem] = []

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
        ZStack(alignment: .bottom) {
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
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showSession) {
            PracticeSessionView(questions: sessionQuestions, attemptsStore: attemptsStore)
        }
    }

    // MARK: - Title Row

    private var titleRow: some View {
        HStack(alignment: .center) {
            Text("Question Bank")
                .font(.largeTitle.bold())
                .foregroundStyle(Color.ink900)

            Spacer()

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

    // MARK: - Attempts Shortcut

    private var attemptsShortcut: some View {
        NavigationLink {
            AttemptsListView()
                .environmentObject(attemptsStore)
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
                    Chip(title: filter.title, isSelected: filter == selectedFilter) {
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
            if filteredQuestions.isEmpty {
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
                            Chip(title: question.category, isSelected: true)
                            Text("Unanswered")
                                .font(.caption)
                                .foregroundStyle(Color.ink500)
                        }
                    }

                    Spacer()

                    if isSelecting {
                        Image(systemName: isSelected ? "checkmark.square.fill" : "square")
                            .foregroundStyle(isSelected ? Color.sage500 : Color.ink300)
                            .font(.system(size: 18, weight: .semibold))
                            .padding(.top, 6)
                    }
                }
            }
            .onTapGesture {
                if isSelecting { onTap() }
            }
        }
    }
}
