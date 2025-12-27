import Foundation

@MainActor
final class JobsStore: ObservableObject {
    @Published private(set) var jobs: [JobApplication] = []

    private let defaults: UserDefaults
    private let storageKey = "jobs_store_v1"
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        self.encoder = encoder

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        self.decoder = decoder

        load()
    }

    func add(_ job: JobApplication) {
        jobs.insert(job, at: 0)
        sortAndPersist()
    }

    func update(_ job: JobApplication) {
        guard let index = jobs.firstIndex(where: { $0.id == job.id }) else { return }
        jobs[index] = job
        sortAndPersist()
    }

    func delete(_ job: JobApplication) {
        jobs.removeAll { $0.id == job.id }
        sortAndPersist()
    }

    func linkStory(jobID: UUID, storyID: UUID) {
        guard let index = jobs.firstIndex(where: { $0.id == jobID }) else { return }
        if !jobs[index].linkedStoryIDs.contains(storyID) {
            jobs[index].linkedStoryIDs.append(storyID)
            sortAndPersist()
        }
    }

    func removeAll() {
        jobs.removeAll()
        persist()
    }

    private func load() {
        guard let data = defaults.data(forKey: storageKey) else { return }
        do {
            jobs = try decoder.decode([JobApplication].self, from: data)
                .sorted { $0.dateApplied > $1.dateApplied }
        } catch {
            jobs = []
        }
    }

    private func sortAndPersist() {
        jobs.sort { $0.dateApplied > $1.dateApplied }
        persist()
    }

    private func persist() {
        do {
            let data = try encoder.encode(jobs)
            defaults.set(data, forKey: storageKey)
        } catch {
            defaults.removeObject(forKey: storageKey)
        }
    }
}

struct JobApplication: Identifiable, Codable, Hashable {
    var id: UUID
    var companyName: String
    var roleTitle: String
    var stage: JobStage
    var locationType: JobLocationType
    var locationDetail: String?
    var salaryMin: String?
    var salaryMax: String?
    var dateApplied: Date
    var nextInterviewDate: Date?
    var nextInterviewNotes: String
    var notes: String
    var linkedStoryIDs: [UUID]

    init(
        id: UUID = UUID(),
        companyName: String,
        roleTitle: String,
        stage: JobStage,
        locationType: JobLocationType,
        locationDetail: String? = nil,
        salaryMin: String? = nil,
        salaryMax: String? = nil,
        dateApplied: Date = Date(),
        nextInterviewDate: Date? = nil,
        nextInterviewNotes: String = "",
        notes: String = "",
        linkedStoryIDs: [UUID] = []
    ) {
        self.id = id
        self.companyName = companyName
        self.roleTitle = roleTitle
        self.stage = stage
        self.locationType = locationType
        self.locationDetail = locationDetail
        self.salaryMin = salaryMin
        self.salaryMax = salaryMax
        self.dateApplied = dateApplied
        self.nextInterviewDate = nextInterviewDate
        self.nextInterviewNotes = nextInterviewNotes
        self.notes = notes
        self.linkedStoryIDs = linkedStoryIDs
    }
}

enum JobLocationType: String, Codable, CaseIterable, Identifiable {
    case remote = "Remote"
    case hybrid = "Hybrid"
    case onsite = "On-site"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .remote:
            return "wifi"
        case .hybrid:
            return "building.2"
        case .onsite:
            return "building"
        }
    }
}
