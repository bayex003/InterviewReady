import SwiftUI
import SwiftData

struct QuestionsListView: View {
    // Keep SwiftData sort simple (stable + compiles)
    @Query(sort: \Question.text, order: .forward) private var questions: [Question]

    @EnvironmentObject private var purchaseManager: PurchaseManager

    @State private var searchText = ""
    @State private var selectedCategory: String = "All"
    @State private var selectedFilter: QuestionFilter = .all
    @State private var showAddQuestion = false
    @State private var showPaywall = false

    let categories = ["All", "General", "Basics", "Behavioral", "Technical", "Strengths", "Weaknesses"]

    // Filter + then sort in-memory (unanswered first)
    private func filteredAndSortedQuestions() -> [Question] {
        let search = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        let category = selectedCategory
        let filter = selectedFilter

        let filtered = questions.filter { q in
            let matchesCategory = (category == "All") || (q.category == category)
            let matchesFilter = (filter == .all) || q.isCustom
            let matchesSearch = search.isEmpty || q.text.localizedCaseInsensitiveContains(search)
            return matchesCategory && matchesFilter && matchesSearch
        }

        return filtered.sorted { lhs, rhs in
            let lhsAnswered = lhs.isAnswered ? 1 : 0
            let rhsAnswered = rhs.isAnswered ? 1 : 0

            if lhsAnswered != rhsAnswered {
                return lhsAnswered < rhsAnswered // unanswered first
            }

            return lhs.text.localizedCaseInsensitiveCompare(rhs.text) == .orderedAscending
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("Filter", selection: $selectedFilter) {
                    ForEach(QuestionFilter.allCases) { filter in
                        Text(filter.rawValue).tag(filter)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.top, 12)

                // Category Filter
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(categories, id: \.self) { cat in
                            CategoryPill(category: cat, selectedCategory: selectedCategory) {
                                selectedCategory = cat
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 12)
                }
                .background(Color.cream50)

                // The List
                List {
                    ForEach(filteredAndSortedQuestions()) { question in
                        NavigationLink(destination: QuestionDetailView(question: question)) {
                            QuestionRow(question: question)
                        }
                        .listRowBackground(Color.surfaceWhite)
                    }
                }
                .listStyle(.plain)
                .safeAreaPadding(.bottom, 90) // prevents last row being covered by floating tab bar
                .background(Color.cream50)

            }
            .navigationTitle("Questions")
            .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always))
            .background(Color.cream50)
            .toolbar {
                Button {
                    if purchaseManager.isPro {
                        showAddQuestion = true
                    } else {
                        showPaywall = true
                    }
                } label: {
                    Image(systemName: "plus")
                }
            }
            .sheet(isPresented: $showAddQuestion) {
                AddQuestionView()
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView()
                    .environmentObject(purchaseManager)
            }
        }
    }
}

private enum QuestionFilter: String, CaseIterable, Identifiable {
    case all = "All"
    case myQuestions = "My Questions"

    var id: String { rawValue }
}

// Subview defined OUTSIDE the main struct
struct CategoryPill: View {
    let category: String
    let selectedCategory: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(category)
                .font(.subheadline)
                .fontWeight(.medium)
                .padding(.vertical, 8)
                .padding(.horizontal, 16)
                .background(selectedCategory == category ? Color.sage500 : Color.surfaceWhite)
                .foregroundColor(selectedCategory == category ? .white : Color.ink600)
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .strokeBorder(Color.ink200, lineWidth: selectedCategory == category ? 0 : 1)
                )
        }
    }
}
