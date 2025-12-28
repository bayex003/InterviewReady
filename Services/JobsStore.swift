import Foundation
import Combine
import SwiftData

/// Compatibility shim.
/// The app previously used JobsStore + JobApplication persisted in UserDefaults.
/// The redesign now uses SwiftData `@Model Job` as the single source of truth.
///
/// Keep this type temporarily so older views still compile while we migrate them.
/// Do not use this for new code.
@MainActor
final class JobsStore: ObservableObject {
    @Published private(set) var jobs: [Job] = []

    private var modelContext: ModelContext?

    init() { }

    /// Call once from a view that has access to SwiftData modelContext if you still need jobsStore somewhere.
    func attach(modelContext: ModelContext) {
        self.modelContext = modelContext
        refresh()
    }

    func refresh() {
        guard let modelContext else { return }
        do {
            let descriptor = FetchDescriptor<Job>(
                sortBy: [SortDescriptor(\Job.dateApplied, order: .reverse)]
            )
            jobs = try modelContext.fetch(descriptor)
        } catch {
            jobs = []
        }
    }

    func add(_ job: Job) {
        guard let modelContext else { return }
        modelContext.insert(job)
        refresh()
    }

    func delete(_ job: Job) {
        guard let modelContext else { return }
        modelContext.delete(job)
        refresh()
    }

    /// Legacy API no-op. Story linking now happens via Story.linkedJob relationship.
    func linkStory(jobID: UUID, storyID: UUID) { }
}

