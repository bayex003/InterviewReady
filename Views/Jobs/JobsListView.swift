import SwiftUI
import SwiftData

struct JobsListView: View {
    @Query(sort: \Job.dateApplied, order: .reverse) private var jobs: [Job]

    @State private var searchText = ""
    @State private var selectedFilter: JobStageFilter = .all
    @State private var showAddJob = false
    @State private var selectedJob: Job?

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
        .navigationDestination(item: $selectedJob) { job in
            JobDetailViewLocal(job: job)
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
                JobCardView(job: job)
                    .onTapGesture { selectedJob = job }
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
                    showAddJob = true
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
}

// MARK: - Card

private struct JobCardView: View {
    let job: Job

    private var nextInterviewText: String? {
        guard let date = job.nextInterviewDate else { return nil }
        return DateFormattersIR.shortWeekday.string(from: date)
    }

    var body: some View {
        CardContainer(backgroundColor: Color.surfaceWhite, cornerRadius: 22, showShadow: false) {
            VStack(alignment: .leading, spacing: 14) {
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
                    }

                    Spacer()
                }

                HStack(spacing: 12) {
                    JobStagePill(stage: job.stage)

                    if let nextInterviewText {
                        Label("Next: \(nextInterviewText)", systemImage: "calendar")
                            .font(.caption)
                            .foregroundStyle(Color.ink500)
                    }
                }

                if let location = job.location, !location.isEmpty {
                    Text(location)
                        .font(.caption)
                        .foregroundStyle(Color.ink500)
                        .lineLimit(1)
                }
            }
        }
    }
}

private struct JobLogoView: View {
    let name: String

    private var initials: String {
        let parts = name.split(separator: " ")
        let letters = parts.prefix(2).compactMap { $0.first }
        return letters.map { String($0) }.joined().uppercased()
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
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(stage.tintIR.opacity(0.15))
            .foregroundStyle(stage.tintIR)
            .clipShape(Capsule())
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

// MARK: - Detail (minimal)

private struct JobDetailViewLocal: View {
    let job: Job

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 16) {
                Text(job.roleTitle)
                    .font(.title2.bold())
                    .foregroundStyle(Color.ink900)

                Text(job.companyName)
                    .font(.subheadline)
                    .foregroundStyle(Color.ink600)

                Divider()

                Chip(title: job.stage.rawValue, isSelected: true)

                if let location = job.location, !location.isEmpty {
                    Text("Location: \(location)")
                        .font(.subheadline)
                        .foregroundStyle(Color.ink700)
                }

                if let salary = job.salary, !salary.isEmpty {
                    Text("Salary: \(salary)")
                        .font(.subheadline)
                        .foregroundStyle(Color.ink700)
                }

                if let date = job.nextInterviewDate {
                    Text("Next interview: \(DateFormattersIR.mediumDate.string(from: date))")
                        .font(.subheadline)
                        .foregroundStyle(Color.ink700)
                }

                if !job.generalNotes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Divider()
                    Text(job.generalNotes)
                        .font(.subheadline)
                        .foregroundStyle(Color.ink700)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 32)
        }
        .background(Color.cream50.ignoresSafeArea())
        .navigationTitle("Application")
        .navigationBarTitleDisplayMode(.inline)
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
