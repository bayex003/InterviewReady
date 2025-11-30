import Foundation

struct InterviewQuestion: Identifiable, Codable {
    let id: UUID
    let category: QuestionCategory
    let text: String
    let whyItMatters: String
    let answerStructure: [String]
    let exampleAnswers: [String]
    let rolePack: RolePack?

    init(id: UUID = UUID(), category: QuestionCategory, text: String, whyItMatters: String, answerStructure: [String], exampleAnswers: [String], rolePack: RolePack? = nil) {
        self.id = id
        self.category = category
        self.text = text
        self.whyItMatters = whyItMatters
        self.answerStructure = answerStructure
        self.exampleAnswers = exampleAnswers
        self.rolePack = rolePack
    }
}
