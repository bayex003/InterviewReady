import Foundation

enum AttemptMode: String, Codable, CaseIterable, Identifiable {
    case speak
    case write

    var id: String { rawValue }

    var title: String {
        rawValue.capitalized
    }
}

struct Attempt: Identifiable, Codable, Hashable {
    let id: UUID
    let timestamp: Date
    let durationSeconds: Int
    let mode: AttemptMode
    let questionId: UUID
    let questionText: String
    let category: String
    let linkedStoryId: UUID?
    let notes: String?
    let rating: Int?

    init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        durationSeconds: Int,
        mode: AttemptMode,
        questionId: UUID,
        questionText: String,
        category: String,
        linkedStoryId: UUID? = nil,
        notes: String? = nil,
        rating: Int? = nil
    ) {
        self.id = id
        self.timestamp = timestamp
        self.durationSeconds = durationSeconds
        self.mode = mode
        self.questionId = questionId
        self.questionText = questionText
        self.category = category
        self.linkedStoryId = linkedStoryId
        self.notes = notes
        self.rating = rating
    }
}
