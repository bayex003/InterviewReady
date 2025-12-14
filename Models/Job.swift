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
    var companyName: String
    var roleTitle: String
    var stage: JobStage
    var dateApplied: Date
    var nextInterviewDate: Date?
    var generalNotes: String
    
    init(companyName: String, roleTitle: String, stage: JobStage = .saved) {
        self.companyName = companyName
        self.roleTitle = roleTitle
        self.stage = stage
        self.dateApplied = Date()
        self.generalNotes = ""
    }
}
