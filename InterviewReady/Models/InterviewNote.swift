import Foundation

struct InterviewNote: Identifiable, Codable {
    let id: UUID
    var companyName: String
    var roleTitle: String
    var date: Date?
    var whyThisRole: String
    var whatILikeAboutCompany: String
    var questionsToAsk: String
    var otherNotes: String

    init(id: UUID = UUID(), companyName: String, roleTitle: String, date: Date? = nil, whyThisRole: String, whatILikeAboutCompany: String, questionsToAsk: String, otherNotes: String) {
        self.id = id
        self.companyName = companyName
        self.roleTitle = roleTitle
        self.date = date
        self.whyThisRole = whyThisRole
        self.whatILikeAboutCompany = whatILikeAboutCompany
        self.questionsToAsk = questionsToAsk
        self.otherNotes = otherNotes
    }
}
