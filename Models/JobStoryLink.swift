import Foundation
import SwiftData

@Model
final class JobStoryLink {
    var id: UUID
    var jobId: UUID
    var storyId: UUID
    var createdAt: Date

    init(jobId: UUID, storyId: UUID, createdAt: Date = Date()) {
        self.id = UUID()
        self.jobId = jobId
        self.storyId = storyId
        self.createdAt = createdAt
    }
}
