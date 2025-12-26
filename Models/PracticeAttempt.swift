// Testing Checklist:
// - Manual: open question, type something, go back → attempt added
// - Manual: open question, do nothing, go back → no attempt
// - Drill: stop recording on a question → drill attempt added
// - Attempt history: Pro user sees list; free user sees locked message + paywall opens
// - App compiles and runs

import Foundation
import SwiftData

@Model
final class PracticeAttempt {
    var id: UUID
    var createdAt: Date
    var source: String
    var durationSeconds: Int?
    var questionId: UUID?
    var questionTextSnapshot: String
    var confidence: Int?
    var notes: String?

    init(
        source: String,
        questionTextSnapshot: String,
        questionId: UUID? = nil,
        durationSeconds: Int? = nil,
        createdAt: Date = Date(),
        confidence: Int? = nil,
        notes: String? = nil
    ) {
        self.id = UUID()
        self.createdAt = createdAt
        self.source = source
        self.durationSeconds = durationSeconds
        self.questionId = questionId
        self.questionTextSnapshot = questionTextSnapshot
        self.confidence = confidence
        self.notes = notes
    }
}
