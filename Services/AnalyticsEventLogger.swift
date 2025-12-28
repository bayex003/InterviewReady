import Foundation

enum AnalyticsEvent: String, CaseIterable {
    case drillStartedRandom = "drill_started_random"
    case drillStartedSelected = "drill_started_selected"
    case drillQuestionSaved = "drill_question_saved"
    case drillCompleted = "drill_completed"
    case questionPractiseTapped = "question_practise_tapped"
    case answerPlaybackStarted = "answer_playback_started"
    case storySaved = "story_saved"
    case jobSaved = "job_saved"
}

struct AnalyticsEventEntry: Codable, Identifiable {
    let id: UUID
    let name: String
    let timestamp: Date

    init(name: String, timestamp: Date = Date()) {
        self.id = UUID()
        self.name = name
        self.timestamp = timestamp
    }
}

@MainActor
final class AnalyticsEventLogger {
    static let shared = AnalyticsEventLogger()

    private let storageKey = "analytics_events_v1"
    private let maxEvents = 200
    private let defaults: UserDefaults

    private(set) var events: [AnalyticsEventEntry] = []

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        load()
    }

    func log(_ event: AnalyticsEvent) {
        let entry = AnalyticsEventEntry(name: event.rawValue)
        events.append(entry)
        if events.count > maxEvents {
            events = Array(events.suffix(maxEvents))
        }
        persist()
    }

    func exportLogFile() throws -> URL {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        let lines = events.map { entry in
            "\(formatter.string(from: entry.timestamp)) — \(entry.name)"
        }

        let header = "InterviewReady Analytics Log\nGenerated: \(formatter.string(from: Date()))\n"
        let content = ([header] + lines).joined(separator: "\n")

        let directory = FileManager.default.temporaryDirectory
        let url = directory.appendingPathComponent("interviewready_analytics_log.txt")
        try content.write(to: url, atomically: true, encoding: .utf8)
        return url
    }

    private func load() {
        guard let data = defaults.data(forKey: storageKey) else { return }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        if let decoded = try? decoder.decode([AnalyticsEventEntry].self, from: data) {
            events = decoded
        }
    }

    private func persist() {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        if let data = try? encoder.encode(events) {
            defaults.set(data, forKey: storageKey)
        }
    }
}
