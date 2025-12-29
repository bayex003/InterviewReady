import SwiftUI
import SwiftData

struct JobsListView: View {
    @Query(sort: \Job.dateApplied, order: .reverse) private var jobs: [Job]
    @Query private var jobStoryLinks: [JobStoryLink]

    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var purchaseManager: PurchaseManager

    @State private var searchText = ""
    @State private var selectedFilter: JobStageFilter = .all
    @State private var showAddJob = false
    @State private var selectedJob: Job?
    @State private var selectedJobForStories: Job?
    @State private var activeSheet: ActiveSheet?

    private enum ActiveSheet: Identifiable {
        case paywall
        case storyPicker(UUID)

        var id: String {
            switch self {
            case .paywall:
                return "paywall"
            case .storyPicker(let id):
                return "storyPicker-\(id)"
            }
        }
    }

    private var proGate: ProGatekeeper {
        ProGatekeeper(isPro: { purchaseManager.isPro }, presentPaywall: { activeSheet = .paywall })
    }

    private var filteredJobs: [Job] {
        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        return jobs.filter { job in
            guard selectedFilter.matches(job) else { return false }
            if trimmed.isEmpty { return true }
            return "\(job.companyName) \(job.roleTitle)".localizedCaseInsensitiveContains(trimmed)
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

                    SectionHeader(title: "My Applications", actionTitle: "") { }

                    if filteredJobs.isEmpty {
                        emptyStateCard
                    } else {
                        jobsSection
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .safeAreaPadding(.bottom, 110)
            }

            FloatingAddButton {
                showAddJob = true
            }
            .floatingAddButtonPosition()
        }
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showAddJob) {
            // NOTE: AddJobView already contains its own NavigationStack in your current file.
            AddJobView()
        }
        .sheet(item: $activeSheet) { sheet in
            switch sheet {
            case .paywall:
                PaywallView()
                    .environmentObject(purchaseManager)
            case .storyPicker(let jobId):
                StoryLinkPickerView(initialSelection: linkedStoryIds(for: jobId)) { selection in
                    updateStoryLinks(for: jobId, selection: selection)
                }
            }
        }
        .navigationDestination(item: $selectedJob) { job in
            JobDetailView(job: job)
        }
        .navigationDestination(item: $selectedJobForStories) { job in
            JobLinkedStoriesView(jobId: job.id)
        }
    }

    // MARK: - UI

    private var headerSection: some View {
        HStack(alignment: .center) {
            Text("My Applications")
                .font(.largeTitle.bold())
                .foregroundStyle(Color.ink900)

            Spacer()

            HStack(spacing: 12) {
                Button { } label: {
                    Image(systemName: "magnifyingglass")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(Color.ink600)
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Search applications")

                Button { } label: {
                    Image(systemName: "bell")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(Color.ink600)
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Notifications")
            }
        }
    }

    private var searchRow: some View {
        CardContainer(backgroundColor: Color.surfaceWhite, cornerRadius: 18, showShadow: false) {
            HStack(spacing: 12) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(Color.ink400)

                TextField("Search applications", text: $searchText)
                    .font(.subheadline)
                    .foregroundStyle(Color.ink900)
            }
        }
    }

    private var filterRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(JobStageFilter.allCases) { filter in
                    Chip(title: filter.title, isSelected: filter == selectedFilter) {
                        selectedFilter = filter
                    }
                }
            }
            .padding(.vertical, 4)
        }
    }

    private var jobsSection: some View {
        VStack(spacing: 16) {
            ForEach(filteredJobs) { job in
                JobCardView(
                    job: job,
                    linkedStoryCount: linkedStoryCount(for: job.id),
                    onSelect: { selectedJob = job },
                    onLinkStory: { handleLinkStoryTapped(for: job.id) },
                    onViewStories: { selectedJobForStories = job }
                )
            }
        }
    }

    // TO →
    private var emptyStateCard: some View {
        Button {
            showAddJob = true
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                Text("Track a new application")
                    .font(.headline)
                    .foregroundStyle(Color.ink900)

                Text("Keep all your opportunities in one place.")
                    .font(.subheadline)
                    .foregroundStyle(Color.ink600)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .strokeBorder(Color.ink200, style: StrokeStyle(lineWidth: 1, dash: [6]))
            )
        }
        .buttonStyle(.plain)
    }

    private func linkedStoryCount(for jobId: UUID) -> Int {
        jobStoryLinks.filter { $0.jobId == jobId }.count
    }

    private func linkedStoryIds(for jobId: UUID) -> Set<UUID> {
        Set(jobStoryLinks.filter { $0.jobId == jobId }.map(\.storyId))
    }

    private func handleLinkStoryTapped(for jobId: UUID) {
        proGate.requirePro(.storyLinking) {
            activeSheet = .storyPicker(jobId)
        }
    }

    private func updateStoryLinks(for jobId: UUID, selection: Set<UUID>) {
        let existingLinks = jobStoryLinks.filter { $0.jobId == jobId }
        let existingIds = Set(existingLinks.map(\.storyId))

        let toRemove = existingLinks.filter { !selection.contains($0.storyId) }
        toRemove.forEach { modelContext.delete($0) }

        let toAdd = selection.subtracting(existingIds)
        toAdd.forEach { storyId in
            let link = JobStoryLink(jobId: jobId, storyId: storyId)
            modelContext.insert(link)
        }

        try? modelContext.save()
    }
}

// MARK: - Card

private struct JobCardView: View {
    let job: Job
    let linkedStoryCount: Int
    let onSelect: () -> Void
    let onLinkStory: () -> Void
    let onViewStories: () -> Void

    private var nextInterviewText: String? {
        guard job.stage == .interviewing, let date = job.nextInterviewDate else { return nil }
        return DateFormattersIR.shortWeekday.string(from: date)
    }

    var body: some View {
        CardContainer(backgroundColor: Color.surfaceWhite, cornerRadius: 22, showShadow: false) {
            VStack(alignment: .leading, spacing: 14) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(job.roleTitle)
                        .font(.headline)
                        .foregroundStyle(Color.ink900)
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)

                    Text(job.companyName)
                        .font(.subheadline)
                        .foregroundStyle(Color.ink600)
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)
                }

                HStack(spacing: 12) {
                    JobStagePill(stage: job.stage)

                    if let nextInterviewText {
                        Label("Next: \(nextInterviewText)", systemImage: "calendar")
                            .font(.caption)
                            .foregroundStyle(Color.ink500)
                    }
                }

                Divider().opacity(0.5)

                if linkedStoryCount > 0 {
                    Button(action: onViewStories) {
                        HStack(spacing: 10) {
                            Image(systemName: "book")
                                .foregroundStyle(Color.sage500)

                            Text("View \(linkedStoryCount) Stories")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(Color.ink700)

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(Color.ink400)
                        }
                        .padding(.vertical, 6)
                    }
                    .buttonStyle(.plain)
                } else {
                    Button(action: onLinkStory) {
                        HStack(spacing: 10) {
                            Image(systemName: "link")
                                .foregroundStyle(Color.ink500)

                            Text("Link Story")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(Color.ink700)

                            Spacer()
                        }
                        .padding(.vertical, 10)
                        .padding(.horizontal, 12)
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .strokeBorder(Color.ink200, style: StrokeStyle(lineWidth: 1, dash: [6]))
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            onSelect()
        }
    }
}

private struct JobStagePill: View {
    let stage: JobStage

    var body: some View {
        Text(stage.rawValue)
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(stage.tintIR.opacity(0.15))
            .foregroundStyle(stage.tintIR)
            .clipShape(Capsule())
    }
}

private struct JobLinkedStoriesView: View {
    let jobId: UUID

    @Environment(\.modelContext) private var modelContext
    @Query private var links: [JobStoryLink]

    init(jobId: UUID) {
        self.jobId = jobId
        _links = Query(filter: #Predicate<JobStoryLink> { $0.jobId == jobId })
    }

    private var linkedStories: [Story] {
        let ids = links.map(\.storyId)
        guard !ids.isEmpty else { return [] }

        let predicate = #Predicate<Story> { ids.contains($0.id) }
        let descriptor = FetchDescriptor<Story>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.lastUpdated, order: .reverse)]
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    var body: some View {
        List {
            if linkedStories.isEmpty {
                ContentUnavailableView("No linked stories", systemImage: "book")
            } else {
                ForEach(linkedStories) { story in
                    NavigationLink {
                        StoryDetailView(story: story)
                    } label: {
                        HStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(story.title)
                                    .font(.headline)
                                    .foregroundStyle(Color.ink900)

                                Text(storyTag(for: story))
                                    .font(.caption)
                                    .foregroundStyle(Color.ink500)
                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(Color.ink400)
                        }
                    }
                }
            }
        }
        .navigationTitle("Linked Stories")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func storyTag(for story: Story) -> String {
        if let firstTag = story.tags.first, !firstTag.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return firstTag
        }
        return story.category
    }
}

private enum JobStageFilter: String, CaseIterable, Identifiable {
    case all
    case saved
    case applied
    case interviewing
    case offer
    case rejected

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all: return "All"
        case .saved: return JobStage.saved.rawValue
        case .applied: return JobStage.applied.rawValue
        case .interviewing: return JobStage.interviewing.rawValue
        case .offer: return JobStage.offer.rawValue
        case .rejected: return JobStage.rejected.rawValue
        }
    }

    func matches(_ job: Job) -> Bool {
        switch self {
        case .all: return true
        case .saved: return job.stage == .saved
        case .applied: return job.stage == .applied
        case .interviewing: return job.stage == .interviewing
        case .offer: return job.stage == .offer
        case .rejected: return job.stage == .rejected
        }
    }
}

// MARK: - Helpers

private enum DateFormattersIR {
    static let shortWeekday: DateFormatter = {
        let df = DateFormatter()
        df.dateFormat = "EEE, d MMM"
        return df
    }()

    static let mediumDate: DateFormatter = {
        let df = DateFormatter()
        df.dateStyle = .medium
        df.timeStyle = .short
        return df
    }()
}

private extension JobStage {
    var tintIR: Color {
        switch self {
        case .saved: return Color.ink500
        case .applied: return Color.sage500
        case .interviewing: return Color.sage500
        case .offer: return Color.sage500
        case .rejected: return Color.ink500
        }
    }
}
