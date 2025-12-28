import Foundation
import SwiftData

@Model
final class Story {
    var id: UUID
    var title: String
    var category: String // Leadership, Conflict, etc.
    var tags: [String]
    var situation: String
    var task: String
    var action: String
    var result: String
    var notes: String
    var linkedJob: Job?
    var dateAdded: Date
    var lastUpdated: Date

    init(title: String, category: String = "General", tags: [String] = []) {
        self.id = UUID()
        self.title = title
        self.category = category
        self.tags = tags
        self.situation = ""
        self.task = ""
        self.action = ""
        self.result = ""
        self.notes = ""
        self.linkedJob = nil
        self.dateAdded = Date()
        self.lastUpdated = Date()
    }
}
