import SwiftUI
import SwiftData

struct JobsListView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var router: AppRouter

    @Query(sort: \Job.dateApplied, order: .reverse) private var allJobs: [Job]

    @State private var searchText = ""
    @State private var showAddJob = false
    @State private var filterSelection = 0

    private var filteredJobs: [Job] {
        let jobsToFilter = allJobs.filter { job in
            if filterSelection == 0 { return job.stage != .rejected }
            else { return job.stage == .rejected }
        }
        if searchText.isEmpty { return jobsToFilter }
        return jobsToFilter.filter {
            $0.companyName.localizedCaseInsensitiveContains(searchText) ||
            $0.roleTitle.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.cream50.ignoresSafeArea()

                VStack(spacing: 0) {
                    Picker("Filter", selection: $filterSelection) {
                        Text("Active").tag(0)
                        Text("Archived").tag(1)
                    }
                    .pickerStyle(.segmented)
                    .padding()
                    .background(Color.cream50)

                    if filteredJobs.isEmpty {
                        ContentUnavailableView(
                            filterSelection == 0 ? "No Active Jobs" : "No Archived Jobs",
                            systemImage: filterSelection == 0 ? "briefcase" : "archivebox"
                        )
                        Spacer()
                    } else {
                        List {
                            ForEach(filteredJobs) { job in
                                NavigationLink(destination: EditJobView(job: job)) {
                                    JobRow(job: job)
                                }
                                .listRowBackground(Color.surfaceWhite)
                            }
                            .onDelete(perform: deleteJob)
                        }
                        .listStyle(.plain)
                    }
                }
            }
            .navigationTitle("My Jobs")
            .searchable(text: $searchText)
            .toolbar {
                Button { showAddJob = true } label: { Image(systemName: "plus") }
            }
            .sheet(isPresented: $showAddJob) { AddJobView() }
            .onChange(of: router.presentAddJob) { _, newValue in
                if newValue {
                    showAddJob = true
                    router.presentAddJob = false
                }
            }
        }
    }

    private func deleteJob(offsets: IndexSet) {
        withAnimation {
            for index in offsets { modelContext.delete(filteredJobs[index]) }
        }
    }
}

// JobRow stays in this file as you already have it
struct JobRow: View {
    let job: Job
    var body: some View {
        HStack {
            ZStack {
                Circle().fill(job.stage.color.opacity(0.15)).frame(width: 48, height: 48)
                Image(systemName: job.stage.icon).foregroundStyle(job.stage.color)
            }
            VStack(alignment: .leading) {
                Text(job.companyName).font(.headline).foregroundStyle(Color.ink900)
                Text(job.roleTitle).font(.subheadline).foregroundStyle(Color.ink600)
            }
            Spacer()
            Text(job.stage.rawValue)
                .font(.caption2).fontWeight(.bold)
                .padding(6).background(job.stage.color.opacity(0.1))
                .foregroundStyle(job.stage.color).clipShape(Capsule())
        }
        .padding().background(Color.surfaceWhite).cornerRadius(16)
    }
}
