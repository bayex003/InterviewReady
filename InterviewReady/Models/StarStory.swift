import Foundation

struct StarStory: Identifiable, Codable {
    let id: UUID
    var title: String
    var situation: String
    var task: String
    var action: String
    var result: String
    var createdAt: Date

    init(id: UUID = UUID(), title: String, situation: String, task: String, action: String, result: String, createdAt: Date = Date()) {
        self.id = id
        self.title = title
        self.situation = situation
        self.task = task
        self.action = action
        self.result = result
        self.createdAt = createdAt
    }

    var assembledNarrative: String {
        "Situation: \(situation)\nTask: \(task)\nAction: \(action)\nResult: \(result)"
    }
}
