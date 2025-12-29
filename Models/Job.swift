import Foundation
import SwiftData

enum JobStage: String, Codable, CaseIterable {
    case saved = "Saved"
    case applied = "Applied"
    case interviewing = "Interviewing"
    case offer = "Offer"
    case rejected = "Rejected"
}

@Model
class Job {
    var id: UUID
    var companyName: String
    var roleTitle: String
    var stage: JobStage
    var dateApplied: Date

    var nextInterviewDate: Date?
    var nextInterviewNotes: String?   // ✅ NEW (optional)

    var generalNotes: String

    // ✅ V2 (free): Details-only fields
    var salary: String?
    var location: String?

    init(companyName: String, roleTitle: String, stage: JobStage = .saved) {
        self.id = UUID()
        self.companyName = companyName
        self.roleTitle = roleTitle
        self.stage = stage
        self.dateApplied = Date()

        self.nextInterviewDate = nil
        self.nextInterviewNotes = nil   // ✅ NEW default

        self.generalNotes = ""

        // Defaults for existing/new jobs
        self.salary = nil
        self.location = nil
    }
}
