import SwiftUI

struct QuestionsListView: View {
    @EnvironmentObject private var attemptsStore: AttemptsStore

    @State private var searchText = ""
    @State private var selectedCategory: QuestionCategory = .all
    @State private var isSelecting = false
    @State private var selectedQuestionIDs: Set<UUID> = []
    @State private var showAddQuestion = false
    @State private var showPracticeSession = false

    private var questions: [QuestionBankItem] {
        QuestionBankItem.sampleData.map { question in
            let answered = isQuestionAnswered(question)
            let linkedStories = linkedStoryCount(for: question)
            return question.with(answered: answered, linkedStories: linkedStories)
        }
    }

    private var filteredQuestions: [QuestionBankItem] {
        let trimmedSearch = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        return questions.filter { question in
            let matchesCategory = selectedCategory == .all || question.category == selectedCategory
            let matchesSearch = trimmedSearch.isEmpty
                || question.text.localizedCaseInsensitiveContains(trimmedSearch)
                || question.tags.contains(where: { $0.localizedCaseInsensitiveContains(trimmedSearch) })
            return matchesCategory && matchesSearch
        }
    }

    private var selectedQuestions: [QuestionBankItem] {
        questions.filter { selectedQuestionIDs.contains($0.id) }
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    titleRow

                    attemptsShortcut

                    searchRow

                    categoryRow

                    questionsContent
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .safeAreaPadding(.bottom, 100)
            }

            FloatingAddButton {
                showAddQuestion = true
            }
            .floatingAddButtonPosition()
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $showAddQuestion) {
            AddQuestionPlaceholderView()
        }
        .navigationDestination(isPresented: $showPracticeSession) {
            PracticeSessionView(questions: selectedQuestions, attemptsStore: attemptsStore)
        }
        .safeAreaInset(edge: .bottom) {
            if isSelecting && !selectedQuestionIDs.isEmpty {
                startSessionButton
            }
        }
    }

    private var titleRow: some View {
        ZStack(alignment: .leading) {
            SectionHeader(title: "", actionTitle: isSelecting ? "Done" : "Select") {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isSelecting.toggle()
                    if !isSelecting {
                        selectedQuestionIDs.removeAll()
                    }
                }
            }

            HStack {
                Text("Question Bank")
                    .font(.largeTitle.bold())
                    .foregroundStyle(Color.ink900)
                Spacer()
            }
        }
    }

    private var attemptsShortcut: some View {
        NavigationLink {
            AttemptsListView(attemptsStore: attemptsStore)
        } label: {
            CardContainer(backgroundColor: Color.surfaceWhite, cornerRadius: 18, showShadow: false) {
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color.sage100)
                            .frame(width: 44, height: 44)

                        Image(systemName: "clock.arrow.circlepath")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(Color.sage500)
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Attempts")
                            .font(.headline)
                            .foregroundStyle(Color.ink900)

                        Text("\(attemptsStore.attempts.count) saved in your history")
                            .font(.subheadline)
                            .foregroundStyle(Color.ink500)
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
    }

    private var searchRow: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(Color.ink400)

            TextField("Search questions or tags…", text: $searchText)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled(true)
                .foregroundStyle(Color.ink900)

            Image(systemName: "mic.fill")
                .foregroundStyle(Color.ink400)
                .accessibilityHidden(true)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 14)
        .background(Color.surfaceWhite)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.ink200, lineWidth: 1)
        )
    }

    private var categoryRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(QuestionCategory.allCases) { category in
                    Chip(
                        title: category.title,
                        isSelected: selectedCategory == category,
                        action: {
                            selectedCategory = category
                        }
                    )
                }
            }
            .padding(.vertical, 4)
        }
    }

    private var questionsContent: some View {
        VStack(spacing: 16) {
            if questions.isEmpty {
                CardContainer(backgroundColor: Color.surfaceWhite, cornerRadius: 22, showShadow: false) {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("No questions yet")
                            .font(.headline)
                            .foregroundStyle(Color.ink900)

                        Text("Add your first interview prompt to start practicing.")
                            .font(.subheadline)
                            .foregroundStyle(Color.ink500)

                        PrimaryCTAButton(title: "Add a question") {
                            showAddQuestion = true
                        }
                    }
                }
            } else if filteredQuestions.isEmpty {
                CardContainer(backgroundColor: Color.surfaceWhite, cornerRadius: 22, showShadow: false) {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("No questions found")
                            .font(.headline)
                            .foregroundStyle(Color.ink900)

                        Text("Try clearing your search or choosing a different category.")
                            .font(.subheadline)
                            .foregroundStyle(Color.ink500)

                        PrimaryCTAButton(title: "Reset filters") {
                            searchText = ""
                            selectedCategory = .all
                        }
                    }
                }
            } else {
                ForEach(filteredQuestions) { question in
                    QuestionBankRow(
                        question: question,
                        isSelecting: isSelecting,
                        isSelected: selectedQuestionIDs.contains(question.id),
                        onToggleSelection: {
                            toggleSelection(for: question)
                        }
                    )
                }
            }
        }
        .padding(.bottom, isSelecting && !selectedQuestionIDs.isEmpty ? 80 : 16)
    }

    private var startSessionButton: some View {
        Button {
            showPracticeSession = true
        } label: {
            Text("Start Session")
                .font(.headline)
                .foregroundStyle(Color.surfaceWhite)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color.sage500)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 20)
        .padding(.bottom, 8)
        .background(Color.cream50.ignoresSafeArea(edges: .bottom))
    }

    private func toggleSelection(for question: QuestionBankItem) {
        if selectedQuestionIDs.contains(question.id) {
            selectedQuestionIDs.remove(question.id)
        } else {
            selectedQuestionIDs.insert(question.id)
        }
    }

    private func isQuestionAnswered(_ question: QuestionBankItem) -> Bool {
        attemptsStore.attempts.contains { attempt in
            attempt.questionId == question.id
                || attempt.questionText.caseInsensitiveCompare(question.text) == .orderedSame
        }
    }

    private func linkedStoryCount(for question: QuestionBankItem) -> Int {
        let linkedStories = attemptsStore.attempts.compactMap { attempt -> UUID? in
            guard attempt.questionId == question.id
                    || attempt.questionText.caseInsensitiveCompare(question.text) == .orderedSame
            else { return nil }
            return attempt.linkedStoryId
        }
        return Set(linkedStories).count
    }
}

private struct QuestionBankRow: View {
    let question: QuestionBankItem
    let isSelecting: Bool
    let isSelected: Bool
    let onToggleSelection: () -> Void

    var body: some View {
        CardContainer(backgroundColor: Color.surfaceWhite, cornerRadius: 18) {
            HStack(alignment: .top, spacing: 12) {
                ZStack(alignment: .bottomTrailing) {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.sage100)
                        .frame(width: 44, height: 44)
                        .overlay(
                            Image(systemName: question.iconName)
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundStyle(Color.sage500)
                        )

                    if question.isAnswered {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 16))
                            .foregroundStyle(Color.sage500)
                            .background(Circle().fill(Color.surfaceWhite))
                            .offset(x: 6, y: 6)
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text(question.text)
                        .font(.headline)
                        .foregroundStyle(Color.ink900)
                        .lineLimit(2)

                    HStack(spacing: 8) {
                        Chip(title: question.category.title, isSelected: true)

                        if question.linkedStories > 0 {
                            HStack(spacing: 4) {
                                Image(systemName: "link")
                                Text("\(question.linkedStories) \(question.linkedStories == 1 ? "Story" : "Stories") Linked")
                            }
                            .font(.subheadline)
                            .foregroundStyle(Color.sage500)
                        } else {
                            Text(question.isAnswered ? "Answered" : "Unanswered")
                                .font(.subheadline)
                                .foregroundStyle(question.isAnswered ? Color.sage500 : Color.ink400)
                        }
                    }
                }

                Spacer()

                if isSelecting {
                    Button(action: onToggleSelection) {
                        Image(systemName: isSelected ? "checkmark.square.fill" : "square")
                            .font(.title3)
                            .foregroundStyle(isSelected ? Color.sage500 : Color.ink300)
                            .frame(width: 44, height: 44)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(isSelected ? "Deselect question" : "Select question")
                }
            }
            .contentShape(Rectangle())
            .onTapGesture {
                if isSelecting {
                    onToggleSelection()
                }
            }
        }
    }
}

enum QuestionCategory: String, CaseIterable, Identifiable {
    case all = "All"
    case behavioral = "Behavioral"
    case technical = "Technical"
    case leadership = "Leadership"

    var id: String { rawValue }
    var title: String { rawValue }
}

struct QuestionBankItem: Identifiable {
    let id: UUID
    let text: String
    let category: QuestionCategory
    let linkedStories: Int
    let isAnswered: Bool
    let iconName: String
    let tags: [String]

    func with(answered: Bool, linkedStories: Int) -> QuestionBankItem {
        QuestionBankItem(
            id: id,
            text: text,
            category: category,
            linkedStories: linkedStories,
            isAnswered: answered,
            iconName: iconName,
            tags: tags
        )
    }

    static let sampleData: [QuestionBankItem] = [
        QuestionBankItem(
            id: UUID(),
            text: "Tell me about a time you failed and how you handled it.",
            category: .behavioral,
            linkedStories: 2,
            isAnswered: true,
            iconName: "message.fill",
            tags: ["failure", "reflection"]
        ),
        QuestionBankItem(
            id: UUID(),
            text: "Explain the concept of Dependency Injection.",
            category: .technical,
            linkedStories: 0,
            isAnswered: false,
            iconName: "terminal",
            tags: ["architecture", "patterns"]
        ),
        QuestionBankItem(
            id: UUID(),
            text: "Where do you see yourself in 5 years?",
            category: .leadership,
            linkedStories: 1,
            isAnswered: true,
            iconName: "star.fill",
            tags: ["career", "vision"]
        ),
        QuestionBankItem(
            id: UUID(),
            text: "Tell me about a time you had to work with a difficult teammate.",
            category: .behavioral,
            linkedStories: 0,
            isAnswered: false,
            iconName: "person.3.fill",
            tags: ["teamwork", "conflict"]
        ),
        QuestionBankItem(
            id: UUID(),
            text: "What is the difference between a process and a thread?",
            category: .technical,
            linkedStories: 0,
            isAnswered: false,
            iconName: "chevron.left.slash.chevron.right",
            tags: ["os", "fundamentals"]
        ),
        QuestionBankItem(
            id: UUID(),
            text: "Describe a time you had to influence without authority.",
            category: .leadership,
            linkedStories: 3,
            isAnswered: true,
            iconName: "sparkles",
            tags: ["influence", "leadership"]
        ),
        QuestionBankItem(
            id: UUID(),
            text: "How do you prioritize when everything feels urgent?",
            category: .leadership,
            linkedStories: 1,
            isAnswered: true,
            iconName: "flag.fill",
            tags: ["prioritization", "planning"]
        ),
        QuestionBankItem(
            id: UUID(),
            text: "Walk me through your approach to debugging a production issue.",
            category: .technical,
            linkedStories: 2,
            isAnswered: true,
            iconName: "wrench.and.screwdriver.fill",
            tags: ["debugging", "production"]
        ),
        QuestionBankItem(
            id: UUID(),
            text: "Tell me about a project you are most proud of.",
            category: .behavioral,
            linkedStories: 1,
            isAnswered: true,
            iconName: "hand.thumbsup.fill",
            tags: ["impact", "delivery"]
        ),
        QuestionBankItem(
            id: UUID(),
            text: "How would you explain a complex technical concept to a non-technical stakeholder?",
            category: .leadership,
            linkedStories: 0,
            isAnswered: false,
            iconName: "bubble.left.and.bubble.right.fill",
            tags: ["communication", "stakeholders"]
        )
    ]
}

private struct AddQuestionPlaceholderView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "plus.circle.fill")
                .font(.system(size: 48))
                .foregroundStyle(Color.sage500)

            Text("Add Question")
                .font(.title2.bold())
                .foregroundStyle(Color.ink900)

            Text("Question creation is coming soon.")
                .font(.subheadline)
                .foregroundStyle(Color.ink500)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.cream50)
    }
}
