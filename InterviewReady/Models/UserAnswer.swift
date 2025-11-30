import Foundation

struct UserAnswer: Identifiable, Codable {
    let id: UUID
    var questionID: UUID?
    var customQuestionText: String?
    var answerText: String
    var category: QuestionCategory
    var isFavourite: Bool
    var createdAt: Date
    var updatedAt: Date

    init(id: UUID = UUID(), questionID: UUID? = nil, customQuestionText: String? = nil, answerText: String, category: QuestionCategory, isFavourite: Bool = false, createdAt: Date = Date(), updatedAt: Date = Date()) {
        self.id = id
        self.questionID = questionID
        self.customQuestionText = customQuestionText
        self.answerText = answerText
        self.category = category
        self.isFavourite = isFavourite
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
