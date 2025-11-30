import Foundation

struct Achievement: Identifiable, Codable {
    let id: UUID
    var title: String
    var description: String
    var impact: String?
    var date: Date

    init(id: UUID = UUID(), title: String, description: String, impact: String? = nil, date: Date = Date()) {
        self.id = id
        self.title = title
        self.description = description
        self.impact = impact
        self.date = date
    }
}
