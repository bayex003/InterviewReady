import SwiftUI
import SwiftData

struct JobsListView: View {
    @EnvironmentObject private var jobsStore: JobsStore
    @EnvironmentObject private var router: AppRouter
    @EnvironmentObject private var purchaseManager: PurchaseManager

    @State private var searchText = ""
    @State private var selectedFilter: JobStageFilter = .all
    @State private var showAddApplication = false
    @State private var linkSheet: JobSheetID?
    @State private var storiesSheet: JobSheetID?
    @State private var showPaywall = false
    @State private var selectedJob: JobApplication?

    private var filteredJobs: [JobApplication] {
        let trimmedSearch = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        return jobsStore.jobs.filter { job in
            guard selectedFilter.matches(job) else { return false }

            if trimmedSearch.isEmpty { return true }

            let searchTarget = "\(job.companyName) \(job.roleTitle)"
            return searchTarget.localizedCaseInsensitiveContains(trimmedSearch)
        }
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Color.cream50.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    headerSection

                    searchRow

                    filterRow

                    SectionHeader(title: "Applications")

                    if filteredJobs.isEmpty {
                        emptyStateCard
                    } else {
                        jobsSection
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .safeAreaPadding(.bottom, 100)
            }

            FloatingAddButton {
                showAddApplication = true
            }
            .floatingAddButtonPosition()
        }
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showAddApplication) {
            NavigationStack {
                AddApplicationView()
            }
        }
        .sheet(item: $linkSheet) { sheet in
            LinkStorySheetView(jobID: sheet.id)
        }
        .sheet(item: $storiesSheet) { sheet in
            LinkedStoriesSheetView(jobID: sheet.id)
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView()
                .environmentObject(purchaseManager)
        }
        .navigationDestination(item: $selectedJob) { job in
            JobApplicationDetailView(
                job: job,
                onViewStories: {
                    storiesSheet = JobSheetID(id: job.id)
                },
                onLinkStory: {
                    handleLinkStory(for: job.id)
                }
            )
        }
        .onChange(of: router.presentAddJob) { _, newValue in
            if newValue {
                showAddApplication = true
                router.presentAddJob = false
            }
        }
        .onChange(of: router.selectedJobID) { _, newValue in
            guard let newValue,
                  let job = jobsStore.jobs.first(where: { $0.id == newValue }) else { return }
            selectedJob = job
            router.selectedJobID = nil
        }
    }

    private var headerSection: some View {
        HStack(alignment: .center) {
            Text("My Applications")
                .font(.largeTitle.bold())
                .foregroundStyle(Color.ink900)

            Spacer()

            HStack(spacing: 12) {
                Button {
                } label: {
                    Image(systemName: "magnifyingglass")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(Color.ink600)
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Search applications")

                Button {
                } label: {
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

    private var jobsSection: some View {
        VStack(spacing: 16) {
            ForEach(filteredJobs) { job in
                JobCardView(
                    job: job,
                    onViewStories: {
                        storiesSheet = JobSheetID(id: job.id)
                    },
                    onLinkStory: {
                        handleLinkStory(for: job.id)
                    },
                    onSelect: {
                        selectedJob = job
                    }
                )
            }
        }
    }

    private var emptyStateCard: some View {
        CardContainer(backgroundColor: Color.surfaceWhite, cornerRadius: 22, showShadow: false) {
            VStack(alignment: .center, spacing: 16) {
                ZStack {
                    Circle()
                        .fill(Color.ink200)
                        .frame(width: 64, height: 64)

                    Image(systemName: "briefcase")
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundStyle(Color.ink500)
                }

                Text("Track a new application")
                    .font(.headline)
                    .foregroundStyle(Color.ink900)

                Text("Keep all your opportunities in one place.")
                    .font(.subheadline)
                    .foregroundStyle(Color.ink500)
                    .multilineTextAlignment(.center)

                PrimaryCTAButton(title: "Add application") {
                    showAddApplication = true
                }
            }
            .frame(maxWidth: .infinity)
        }
        .overlay(
            RoundedRectangle(cornerRadius: 22)
                .stroke(style: StrokeStyle(lineWidth: 1, dash: [6]))
                .foregroundStyle(Color.ink200)
        )
    }

    private func handleLinkStory(for jobID: UUID) {
        guard purchaseManager.isPro else {
            showPaywall = true
            return
        }

        linkSheet = JobSheetID(id: jobID)
    }
}

private struct JobCardView: View {
    let job: JobApplication
    let onViewStories: () -> Void
    let onLinkStory: () -> Void
    let onSelect: () -> Void

    private var formattedNextInterview: String? {
        guard let date = job.nextInterviewDate else { return nil }
        return DateFormatters.shortWeekday.string(from: date)
    }

    var body: some View {
        CardContainer(backgroundColor: Color.surfaceWhite, cornerRadius: 22, showShadow: false) {
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .top, spacing: 12) {
                    JobLogoView(name: job.companyName)

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

                        if let location = job.locationDetail, !location.isEmpty {
                            Text(location)
                                .font(.caption)
                                .foregroundStyle(Color.ink500)
                                .lineLimit(1)
                                .minimumScaleFactor(0.85)
                        }
                    }

                    Spacer()

                    Image(systemName: "bookmark")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(Color.ink400)
                }

                HStack(spacing: 12) {
                    JobStagePill(stage: job.stage)

                    if let formattedNextInterview {
                        Label("Next: \(formattedNextInterview)", systemImage: "calendar")
                            .font(.caption)
                            .foregroundStyle(Color.ink500)
                    }
                }

                if job.linkedStoryIDs.count > 0 {
                    Text("\(job.linkedStoryIDs.count) stories linked")
                        .font(.caption)
                        .foregroundStyle(Color.ink500)
                }

                Divider()

                HStack(spacing: 12) {
                    Button(action: onViewStories) {
                        Label(viewStoriesTitle, systemImage: "book")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color.sage500)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(Color.sage100)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                    .disabled(job.linkedStoryIDs.isEmpty)

                    Button(action: onLinkStory) {
                        Label("Link Story", systemImage: "paperclip")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color.ink600)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(Color.surfaceWhite)
                            .overlay(
                                Capsule()
                                    .stroke(style: StrokeStyle(lineWidth: 1, dash: [5]))
                                    .foregroundStyle(Color.ink200)
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

    private var viewStoriesTitle: String {
        if job.linkedStoryIDs.count == 1 {
            return "View 1 Story"
        }
        return "View \(job.linkedStoryIDs.count) Stories"
    }
}

private struct JobApplicationDetailView: View {
    let job: JobApplication
    let onViewStories: () -> Void
    let onLinkStory: () -> Void

    private var locationText: String {
        if let location = job.locationDetail, !location.isEmpty {
            return location
        }
        return job.locationType.rawValue
    }

    private var linkedStoriesText: String {
        if job.linkedStoryIDs.count == 1 {
            return "1 story linked"
        }
        return "\(job.linkedStoryIDs.count) stories linked"
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                header
                detailsSection
                linkedStoriesSection
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 32)
        }
        .background(Color.cream50.ignoresSafeArea())
        .navigationTitle("Application")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(job.roleTitle)
                .font(.title2.bold())
                .foregroundStyle(Color.ink900)
                .lineLimit(2)
                .minimumScaleFactor(0.85)

            Text(job.companyName)
                .font(.subheadline)
                .foregroundStyle(Color.ink600)
                .lineLimit(1)
                .minimumScaleFactor(0.85)
        }
    }

    private var detailsSection: some View {
        CardContainer(backgroundColor: Color.surfaceWhite, cornerRadius: 18, showShadow: false) {
            VStack(alignment: .leading, spacing: 12) {
                Text("Stage")
                    .font(.caption)
                    .foregroundStyle(Color.ink400)

                Chip(title: job.stage.rawValue, isSelected: true)

                Divider()

                VStack(alignment: .leading, spacing: 6) {
                    Text("Location")
                        .font(.caption)
                        .foregroundStyle(Color.ink400)

                    Text(locationText)
                        .font(.subheadline)
                        .foregroundStyle(Color.ink700)
                        .lineLimit(2)
                        .minimumScaleFactor(0.85)
                }

                Divider()

                VStack(alignment: .leading, spacing: 6) {
                    Text("Applied")
                        .font(.caption)
                        .foregroundStyle(Color.ink400)

                    Text(DateFormatters.mediumDate.string(from: job.dateApplied))
                        .font(.subheadline)
                        .foregroundStyle(Color.ink700)
                }
            }
        }
    }

    private var linkedStoriesSection: some View {
        CardContainer(backgroundColor: Color.surfaceWhite, cornerRadius: 18, showShadow: false) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Linked Stories")
                        .font(.headline)
                        .foregroundStyle(Color.ink900)

                    Spacer()

                    Text(linkedStoriesText)
                        .font(.caption)
                        .foregroundStyle(Color.ink500)
                }

                HStack(spacing: 12) {
                    Button(action: onViewStories) {
                        Label("View", systemImage: "book")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color.sage500)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(Color.sage100)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                    .disabled(job.linkedStoryIDs.isEmpty)

                    Button(action: onLinkStory) {
                        Label("Link Story", systemImage: "paperclip")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color.ink600)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(Color.surfaceWhite)
                            .overlay(
                                Capsule()
                                    .stroke(style: StrokeStyle(lineWidth: 1, dash: [5]))
                                    .foregroundStyle(Color.ink200)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

private struct JobLogoView: View {
    let name: String

    private var initials: String {
        let components = name.split(separator: " ")
        let initials = components.prefix(2).compactMap { $0.first }
        return initials.map { String($0) }.joined().uppercased()
    }

    var body: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(Color.sage100)
            .frame(width: 52, height: 52)
            .overlay(
                Text(initials.isEmpty ? "?" : initials)
                    .font(.headline)
                    .foregroundStyle(Color.sage500)
            )
    }
}

private struct JobStagePill: View {
    let stage: JobStage

    var body: some View {
        Text(stage.rawValue)
            .font(.caption)
            .fontWeight(.semibold)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(stage.tint.opacity(0.15))
            .foregroundStyle(stage.tint)
            .clipShape(Capsule())
    }
}

private enum JobStageFilter: String, CaseIterable, Identifiable {
    case all
    case applied
    case interviewing
    case offer
    case rejected

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all:
            return "All"
        case .applied:
            return JobStage.applied.rawValue
        case .interviewing:
            return JobStage.interviewing.rawValue
        case .offer:
            return JobStage.offer.rawValue
        case .rejected:
            return JobStage.rejected.rawValue
        }
    }

    func matches(_ job: JobApplication) -> Bool {
        switch self {
        case .all:
            return true
        case .applied:
            return job.stage == .applied
        case .interviewing:
            return job.stage == .interviewing
        case .offer:
            return job.stage == .offer
        case .rejected:
            return job.stage == .rejected
        }
    }
}

private struct JobSheetID: Identifiable {
    let id: UUID
}

private struct LinkStorySheetView: View {
    let jobID: UUID

    @EnvironmentObject private var jobsStore: JobsStore
    @EnvironmentObject private var purchaseManager: PurchaseManager
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Story.lastUpdated, order: .reverse) private var stories: [Story]

    @State private var selectedStoryID: UUID?
    @State private var showPaywall = false

    private var linkedStoryIDs: [UUID] {
        jobsStore.jobs.first(where: { $0.id == jobID })?.linkedStoryIDs ?? []
    }

    var body: some View {
        NavigationStack {
            List {
                if stories.isEmpty {
                    ContentUnavailableView("No stories yet", systemImage: "book.closed")
                } else {
                    ForEach(stories) { story in
                        Button {
                            selectedStoryID = story.id
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

                                if linkedStoryIDs.contains(story.id) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(Color.sage500)
                                } else if selectedStoryID == story.id {
                                    Image(systemName: "circle.inset.filled")
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
                ToolbarItem(placement: .confirmationAction) {
                    Button("Link") {
                        guard purchaseManager.isPro else {
                            showPaywall = true
                            return
                        }
                        guard let selectedStoryID else { return }
                        jobsStore.linkStory(jobID: jobID, storyID: selectedStoryID)
                        dismiss()
                    }
                    .disabled(selectedStoryID == nil)
                }
            }
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView()
                .environmentObject(purchaseManager)
        }
    }
}

private struct LinkedStoriesSheetView: View {
    let jobID: UUID

    @EnvironmentObject private var jobsStore: JobsStore
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Story.lastUpdated, order: .reverse) private var stories: [Story]

    private var linkedStories: [Story] {
        let linkedIDs = Set(jobsStore.jobs.first(where: { $0.id == jobID })?.linkedStoryIDs ?? [])
        return stories.filter { linkedIDs.contains($0.id) }
    }

    var body: some View {
        NavigationStack {
            List {
                if linkedStories.isEmpty {
                    ContentUnavailableView("No linked stories", systemImage: "book")
                } else {
                    ForEach(linkedStories) { story in
                        VStack(alignment: .leading, spacing: 6) {
                            Text(story.title)
                                .font(.headline)
                                .foregroundStyle(Color.ink900)

                            Text(story.category)
                                .font(.caption)
                                .foregroundStyle(Color.ink500)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle("Linked Stories")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

private extension JobStage {
    var tint: Color {
        switch self {
        case .saved:
            return Color.ink500
        case .applied:
            return Color.sage500
        case .interviewing:
            return Color.sage500
        case .offer:
            return Color.sage500
        case .rejected:
            return Color.ink500
        }
    }
}
