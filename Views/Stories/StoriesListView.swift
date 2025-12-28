// FILE: StoryBankView.swift
// REPLACE THE ENTIRE FILE CONTENT WITH THIS

import SwiftUI
import SwiftData

struct StoryBankView: View {
    @Query(sort: \Story.lastUpdated, order: .reverse) private var stories: [Story]
    @EnvironmentObject private var router: AppRouter
    @EnvironmentObject private var purchaseManager: PurchaseManager

    @State private var searchText = ""
    @State private var selectedFilter: StoryFilter = .all
    @State private var showAddStory = false
    @State private var showPaywall = false

    // MARK: - V2 Free Limit (Stories)
    private let freeStoryLimit = 10

    private var hasReachedFreeLimit: Bool {
        !purchaseManager.isPro && stories.count >= freeStoryLimit
    }

    private var filters: [StoryFilter] {
        let tags = StoryStore(stories: stories).allTags

        let categories = Array(
            Set(
                stories
                    .map { $0.category.trimmingCharacters(in: .whitespacesAndNewlines) }
                    .filter { !$0.isEmpty && $0.lowercased() != "general" }
            )
        ).sorted()

        let combined = Array(Set(tags + categories)).sorted()

        return [.all] + combined.map { StoryFilter(title: $0, value: $0) }
    }

    private var filteredStories: [Story] {
        let trimmedSearch = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        return stories.filter { story in
            guard selectedFilter.matches(story) else { return false }

            if trimmedSearch.isEmpty { return true }

            let normalizedTags = StoryStore.normalizeTags(story.tags)
            let matchesTitle = story.title.localizedCaseInsensitiveContains(trimmedSearch)
            let matchesTags = normalizedTags.contains(where: { $0.localizedCaseInsensitiveContains(trimmedSearch) })
            let matchesCategory = story.category.localizedCaseInsensitiveContains(trimmedSearch)
            let matchesNotes = story.notes.localizedCaseInsensitiveContains(trimmedSearch)

            return matchesTitle || matchesTags || matchesCategory || matchesNotes
        }
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Color.cream50.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    headerSection

                    searchRow

                    filterRow

                    if stories.isEmpty {
                        emptyStateCard
                    } else if filteredStories.isEmpty {
                        noResultsCard
                    } else {
                        storiesSection
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .safeAreaPadding(.bottom, 120)
            }

            FloatingAddButton {
                handleAddTapped()
            }
            .floatingAddButtonPosition()
        }
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showAddStory) {
            NewStoryView()
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView()
                .environmentObject(purchaseManager)
        }
        .onChange(of: router.presentAddMoment) { _, newValue in
            if newValue {
                handleAddTapped()
                router.presentAddMoment = false
            }
        }
        .onChange(of: stories) { _, _ in
            refreshSelectedFilter()
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Story Bank")
                    .font(.largeTitle.bold())
                    .foregroundStyle(Color.ink900)

                Text("Capture your best moments")
                    .font(.subheadline)
                    .foregroundStyle(Color.ink500)
            }

            Spacer()

            NavigationLink {
                SettingsView()
            } label: {
                Image(systemName: "gearshape")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(Color.ink600)
                    .frame(width: 44, height: 44)
                    .background(Circle().fill(Color.surfaceWhite))
                    .overlay(Circle().stroke(Color.ink200, lineWidth: 1))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Settings")
        }
    }

    // MARK: - Search

    private var searchRow: some View {
        CardContainer(backgroundColor: Color.surfaceWhite, cornerRadius: 18, showShadow: false) {
            HStack(spacing: 12) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(Color.ink400)

                TextField("Search skills, projects, or tags…", text: $searchText)
                    .font(.subheadline)
                    .foregroundStyle(Color.ink900)
            }
        }
    }

    // MARK: - Filters

    private var filterRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(filters) { filter in
                    Chip(
                        title: filter.title,
                        isSelected: filter == selectedFilter
                    ) {
                        selectedFilter = filter
                    }
                }
            }
            .padding(.vertical, 4)
        }
    }

    // MARK: - List

    private var storiesSection: some View {
        VStack(spacing: 16) {
            ForEach(filteredStories) { story in
                NavigationLink {
                    NewStoryView(story: story)
                } label: {
                    StoryCardView(story: story)
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Empty / No results (matches redesign vibe)

    private var emptyStateCard: some View {
        EmptyStateCard(
            systemImage: "lightbulb.fill",
            title: "Need inspiration?",
            subtitle: "Try adding a story about a time you handled a tight deadline.",
            ctaTitle: "Write your first story",
            action: { handleAddTapped() }
        )
    }

    private var noResultsCard: some View {
        CardContainer(backgroundColor: Color.surfaceWhite, cornerRadius: 22, showShadow: false) {
            VStack(alignment: .leading, spacing: 10) {
                Text("No stories found")
                    .font(.headline)
                    .foregroundStyle(Color.ink900)

                Text("Try a different search or filter to see more results.")
                    .font(.subheadline)
                    .foregroundStyle(Color.ink500)
            }
        }
    }

    // MARK: - Add gating

    private func handleAddTapped() {
        if hasReachedFreeLimit {
            showPaywall = true
        } else {
            showAddStory = true
        }
    }

    private func refreshSelectedFilter() {
        guard !filters.contains(selectedFilter) else { return }
        selectedFilter = .all
    }
}

private struct StoryFilter: Identifiable, Hashable {
    let id: String
    let title: String
    let value: String?

    static let all = StoryFilter(title: "All", value: nil)

    init(title: String, value: String?) {
        self.title = title
        self.value = value
        self.id = value?.lowercased() ?? "all"
    }

    func matches(_ story: Story) -> Bool {
        guard let value else { return true }
        let trimmedValue = value.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedValue.isEmpty { return true }
        let normalizedTags = StoryStore.normalizeTags(story.tags)

        let matchesTags = normalizedTags.contains(where: { $0.localizedCaseInsensitiveContains(trimmedValue) })
        let matchesCategory = story.category.localizedCaseInsensitiveContains(trimmedValue)

        return matchesTags || matchesCategory
    }
}

private struct StoryCardView: View {
    let story: Story

    private var formattedDate: String {
        DateFormatters.mediumDate.string(from: story.lastUpdated)
    }

    private var displayTags: [String] {
        let normalizedTags = StoryStore.sortedTags(story.tags)
        let tags = normalizedTags.isEmpty ? [story.category] : normalizedTags
        return Array(tags.prefix(2))
    }

    private var cardDescription: String {
        let fields = [story.situation, story.task, story.action, story.result]
        let filled = fields.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        if filled.isEmpty {
            return "Add STAR details to make this story stronger."
        }
        return filled.joined(separator: " • ")
    }

    var body: some View {
        CardContainer(backgroundColor: Color.surfaceWhite, cornerRadius: 22, showShadow: false) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(story.title)
                            .font(.headline)
                            .foregroundStyle(Color.ink900)
                            .lineLimit(2)
                            .minimumScaleFactor(0.9)

                        Text(formattedDate)
                            .font(.caption)
                            .foregroundStyle(Color.ink400)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .foregroundStyle(Color.ink300)
                }

                Text(cardDescription)
                    .font(.subheadline)
                    .foregroundStyle(Color.ink500)
                    .lineLimit(2)
                    .minimumScaleFactor(0.9)

                HStack(spacing: 8) {
                    ForEach(displayTags, id: \.self) { tag in
                        Chip(title: tag, isSelected: true)
                    }
                }
            }
        }
    }
}
