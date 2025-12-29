import Foundation
import SwiftData

@Model
final class QuestionStoryLink {
    var id: UUID
    var questionId: UUID
    var storyId: UUID
    var createdAt: Date

    init(questionId: UUID, storyId: UUID, createdAt: Date = Date()) {
        self.id = UUID()
        self.questionId = questionId
        self.storyId = storyId
        self.createdAt = createdAt
    }
}
