import Foundation
import SwiftData

enum JobStage: String, CaseIterable, Codable {
    case applied = "Applied"
    case screening = "Screening"
    case interview = "Interview"
    case offer = "Offer"
    case rejected = "Rejected"
}

@Model
final class Job {
    var id: UUID
    var companyName: String
    var roleTitle: String
    var stageValue: String // Stored as string, accessed via enum helper
    var dateApplied: Date
    var nextInterviewDate: Date?
    var jobDescriptionLink: String?
    var generalNotes: String
    
    // Relationships (To be added later when Question/Story models exist)
    // @Relationship(deleteRule: .nullify) var linkedQuestions: [Question]?
    // @Relationship(deleteRule: .nullify) var linkedStories: [Story]?
    
    init(companyName: String, roleTitle: String, stage: JobStage = .applied) {
        self.id = UUID()
        self.companyName = companyName
        self.roleTitle = roleTitle
        self.stageValue = stage.rawValue
        self.dateApplied = Date()
        self.generalNotes = ""
    }
    
    // Helper to get/set enum
    var stage: JobStage {
        get { JobStage(rawValue: stageValue) ?? .applied }
        set { stageValue = newValue.rawValue }
    }
}
