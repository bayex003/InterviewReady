import SwiftUI
import SwiftData

struct AttemptsListView: View {
    @ObservedObject var attemptsStore: AttemptsStore
    @Query private var stories: [Story]

    @Environment(\.dismiss) private var dismiss

    @State private var searchText = ""
    @State private var selectedFilter: AttemptFilter = .all

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                header
                searchRow
                filterRow
                attemptsContent
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 24)
        }
        .tapToDismissKeyboard()
        .background(Color.cream50.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
    }

    private var header: some View {
        Text("Attempts")
            .font(.largeTitle.bold())
            .foregroundStyle(Color.ink900)
    }

    private var searchRow: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(Color.ink400)

            TextField("Search attempts…", text: $searchText)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled(true)
                .foregroundStyle(Color.ink900)

            Image(systemName: "line.3.horizontal.decrease.circle")
                .foregroundStyle(Color.ink400)
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

    private var filterRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(AttemptFilter.allCases) { filter in
                    Chip(
                        title: filter.title,
                        isSelected: selectedFilter == filter,
                        action: { selectedFilter = filter }
                    )
                }
            }
            .padding(.vertical, 4)
        }
    }

    private var attemptsContent: some View {
        let groupedAttempts = groupedFilteredAttempts
        return VStack(alignment: .leading, spacing: 16) {
            if groupedAttempts.isEmpty {
                CardContainer(backgroundColor: Color.surfaceWhite, cornerRadius: 18, showShadow: false) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("No attempts yet")
                            .font(.headline)
                            .foregroundStyle(Color.ink900)

                        Text("Save a session summary to keep your practice history here.")
                            .font(.subheadline)
                            .foregroundStyle(Color.ink500)

                        PrimaryCTAButton(title: "Start practicing") {
                            dismiss()
                        }
                    }
                }
            } else {
                ForEach(groupedAttempts, id: \.date) { group in
                    VStack(alignment: .leading, spacing: 12) {
                        SectionHeader(title: formattedDate(group.date))

                        VStack(spacing: 12) {
                            ForEach(group.attempts) { attempt in
                                NavigationLink {
                                    AttemptDetailView(attempt: attempt, attemptsStore: attemptsStore)
                                } label: {
                                    AttemptRow(
                                        attempt: attempt,
                                        linkedStoryTitle: storyTitle(for: attempt)
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
            }
        }
    }

    private var filteredAttempts: [Attempt] {
        let trimmedSearch = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        let filtered = attemptsStore.attempts.filter { attempt in
            let matchesSearch = trimmedSearch.isEmpty
                || attempt.questionText.localizedCaseInsensitiveContains(trimmedSearch)
            let matchesFilter = selectedFilter.matches(attempt: attempt)
            return matchesSearch && matchesFilter
        }
        return filtered.sorted { $0.timestamp > $1.timestamp }
    }

    private var groupedFilteredAttempts: [AttemptGroup] {
        let grouped = Dictionary(grouping: filteredAttempts) { attempt in
            Calendar.current.startOfDay(for: attempt.timestamp)
        }
        return grouped
            .map { AttemptGroup(date: $0.key, attempts: $0.value.sorted { $0.timestamp > $1.timestamp }) }
            .sorted { $0.date > $1.date }
    }

    private func formattedDate(_ date: Date) -> String {
        if Calendar.current.isDateInToday(date) {
            return "Today"
        }
        if Calendar.current.isDateInYesterday(date) {
            return "Yesterday"
        }
        return DateFormatters.mediumDate.string(from: date)
    }

    private func storyTitle(for attempt: Attempt) -> String? {
        guard let storyId = attempt.linkedStoryId else { return nil }
        return stories.first(where: { $0.id == storyId })?.title
    }
}

private struct AttemptRow: View {
    let attempt: Attempt
    let linkedStoryTitle: String?

    var body: some View {
        CardContainer(backgroundColor: Color.surfaceWhite, cornerRadius: 18, showShadow: false) {
            VStack(alignment: .leading, spacing: 10) {
                Text(attempt.questionText)
                    .font(.headline)
                    .foregroundStyle(Color.ink900)
                    .lineLimit(2)

                if let linkedStoryTitle {
                    Text("Linked story: \(linkedStoryTitle)")
                        .font(.subheadline)
                        .foregroundStyle(Color.ink600)
                        .lineLimit(1)
                }

                HStack(spacing: 8) {
                    Chip(title: attempt.mode.title, isSelected: true)
                    Text(formattedDuration)
                        .font(.subheadline)
                        .foregroundStyle(Color.ink500)

                    Spacer()

                    Text(formattedTime)
                        .font(.caption)
                        .foregroundStyle(Color.ink400)
                }
            }
        }
    }

    private var formattedDuration: String {
        let minutes = attempt.durationSeconds / 60
        let seconds = attempt.durationSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    private var formattedTime: String {
        DateFormatters.timeOnly.string(from: attempt.timestamp)
    }
}

private struct AttemptGroup: Identifiable {
    let id = UUID()
    let date: Date
    let attempts: [Attempt]
}

private enum AttemptFilter: String, CaseIterable, Identifiable {
    case all = "All"
    case speak = "Speak"
    case write = "Write"
    case today = "Today"
    case thisWeek = "This Week"

    var id: String { rawValue }

    var title: String { rawValue }

    func matches(attempt: Attempt) -> Bool {
        switch self {
        case .all:
            return true
        case .speak:
            return attempt.mode == .speak
        case .write:
            return attempt.mode == .write
        case .today:
            return Calendar.current.isDateInToday(attempt.timestamp)
        case .thisWeek:
            guard let interval = Calendar.current.dateInterval(of: .weekOfYear, for: Date()) else {
                return false
            }
            return interval.contains(attempt.timestamp)
        }
    }
}
