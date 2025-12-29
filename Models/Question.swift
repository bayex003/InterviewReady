import Foundation
import SwiftData

@Model
final class Question {
    var id: UUID
    var text: String
    var category: String
    var tags: [String]
    var isAnswered: Bool
    var answerText: String
    var dateAdded: Date
    var dateAnswered: Date?
    var isCustom: Bool
    var createdAt: Date
    var updatedAt: Date
    var draftNotes: String

    // NEW (V1.1+)
    var tip: String?
    var exampleAnswer: String?

    init(
        text: String,
        category: String = "General",
        isCustom: Bool = false,
        tags: [String] = [],
        draftNotes: String = "",
        tip: String? = nil,
        exampleAnswer: String? = nil
    ) {
        self.id = UUID()
        self.text = text
        self.category = category
        self.tags = tags
        self.isAnswered = false
        self.answerText = ""
        self.dateAdded = Date()
        self.dateAnswered = nil
        self.isCustom = isCustom
        let now = Date()
        self.createdAt = now
        self.updatedAt = now
        self.draftNotes = draftNotes
        self.tip = tip
        self.exampleAnswer = exampleAnswer
    }
}
