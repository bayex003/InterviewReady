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
    @State private var pendingSuggestion: String? = nil

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
                        inspirationCard
                    } else if filteredStories.isEmpty {
                        noResultsCard
                        inspirationCard
                    } else {
                        storiesSection
                        inspirationCard
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
        .sheet(isPresented: $showAddStory, onDismiss: {
            pendingSuggestion = nil
        }) {
            NewStoryView(suggestedTitle: pendingSuggestion)
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

    private var inspirationCard: some View {
        CardContainer(backgroundColor: Color.surfaceWhite, cornerRadius: 24, showShadow: false) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 10) {
                    ZStack {
                        Circle()
                            .fill(Color.sage100)
                            .frame(width: 36, height: 36)

                        Image(systemName: "sparkles")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(Color.sage500)
                    }

                    Text("Need inspiration?")
                        .font(.headline)
                        .foregroundStyle(Color.ink900)

                    Spacer()
                }

                Text(currentInspirationSuggestion)
                    .font(.subheadline)
                    .foregroundStyle(Color.ink500)

                Button {
                    handleAddTapped(suggestedTitle: currentInspirationSuggestion)
                } label: {
                    Text("Add this story")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.sage500)
                        .padding(.vertical, 6)
                        .padding(.horizontal, 12)
                        .background(
                            Capsule()
                                .fill(Color.sage100.opacity(0.7))
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .onTapGesture {
            handleAddTapped(suggestedTitle: currentInspirationSuggestion)
        }
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

    private var inspirationSuggestions: [String] {
        [
            "Share a moment when you handled a tight deadline.",
            "Describe a time you influenced a team decision.",
            "Tell a story about improving a process or workflow."
        ]
    }

    private var currentInspirationSuggestion: String {
        let day = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 0
        return inspirationSuggestions[day % inspirationSuggestions.count]
    }

    private func handleAddTapped(suggestedTitle: String? = nil) {
        if hasReachedFreeLimit {
            showPaywall = true
        } else {
            pendingSuggestion = suggestedTitle
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
        let filled = fields
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        guard !filled.isEmpty else {
            return "Add STAR details to make this story stronger."
        }

        return filled.prefix(2).joined(separator: " • ")
    }

    var body: some View {
        CardContainer(backgroundColor: Color.surfaceWhite, cornerRadius: 22, showShadow: false) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .center, spacing: 8) {
                    HStack(spacing: 6) {
                        ForEach(displayTags, id: \.self) { tag in
                            StoryTagPill(title: tag)
                        }
                    }

                    Spacer()

                    Text(formattedDate)
                        .font(.caption)
                        .foregroundStyle(Color.ink400)
                }

                Text(story.title)
                    .font(.headline)
                    .foregroundStyle(Color.ink900)
                    .lineLimit(2)
                    .minimumScaleFactor(0.9)

                Text(cardDescription)
                    .font(.subheadline)
                    .foregroundStyle(Color.ink500)
                    .lineLimit(2)
                    .minimumScaleFactor(0.9)

                HStack {
                    Text(statusText)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(statusColor)

                    Spacer()

                    StarProgressView(segments: starSegments)
                }
            }
        }
    }

    private var starSegments: [StarSegment] {
        [
            StarSegment(title: "S", isComplete: hasSituation),
            StarSegment(title: "T", isComplete: hasTask),
            StarSegment(title: "A", isComplete: hasAction),
            StarSegment(title: "R", isComplete: hasResult)
        ]
    }

    private var statusText: String {
        if hasSituation && hasTask && hasAction && hasResult {
            return "STAR READY"
        }

        if hasSituation && hasTask && hasAction && !hasResult {
            return "ADD RESULT"
        }

        return "IN PROGRESS"
    }

    private var statusColor: Color {
        if hasSituation && hasTask && hasAction && hasResult {
            return Color.sage500
        }

        return Color.ink500
    }

    private var hasSituation: Bool {
        !story.situation.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var hasTask: Bool {
        !story.task.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var hasAction: Bool {
        !story.action.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var hasResult: Bool {
        !story.result.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

private struct StoryTagPill: View {
    let title: String

    private var foregroundColor: Color {
        TagColorResolver.color(forTag: title)
    }

    private var backgroundColor: Color {
        TagColorResolver.background(forTag: title)
    }

    var body: some View {
        Text(title)
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .foregroundStyle(foregroundColor)
            .background(
                Capsule()
                    .fill(backgroundColor)
            )
            .overlay(
                Capsule()
                    .stroke(foregroundColor.opacity(0.25), lineWidth: 1)
            )
    }
}

private struct StarSegment: Identifiable {
    let id = UUID()
    let title: String
    let isComplete: Bool
}

private struct StarProgressView: View {
    let segments: [StarSegment]

    var body: some View {
        HStack(spacing: 6) {
            ForEach(segments) { segment in
                Text(segment.title)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(segment.isComplete ? Color.sage500 : Color.ink400)
                    .frame(width: 20, height: 20)
                    .background(
                        Capsule()
                            .fill(segment.isComplete ? Color.sage100 : Color.ink200.opacity(0.5))
                    )
            }
        }
    }
}
