import Foundation
import SwiftData

@Model
final class Story {
    var id: UUID
    var title: String
    var category: String // Leadership, Conflict, etc.
    var situation: String
    var task: String
    var action: String
    var result: String
    var dateAdded: Date
    
    init(title: String, category: String = "General") {
        self.id = UUID()
        self.title = title
        self.category = category
        self.situation = ""
        self.task = ""
        self.action = ""
        self.result = ""
        self.dateAdded = Date()
    }
}
