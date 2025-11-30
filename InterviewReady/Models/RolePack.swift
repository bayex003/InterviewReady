import Foundation

struct RolePack: Identifiable, Codable, Equatable {
    let id: UUID
    let name: String
    let description: String
    let isProOnly: Bool

    init(id: UUID = UUID(), name: String, description: String, isProOnly: Bool) {
        self.id = id
        self.name = name
        self.description = description
        self.isProOnly = isProOnly
    }
}
