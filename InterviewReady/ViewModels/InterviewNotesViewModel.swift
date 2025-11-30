import Foundation

@MainActor
final class InterviewNotesViewModel: ObservableObject {
    @Published var draft = InterviewNote(companyName: "", roleTitle: "", whyThisRole: "", whatILikeAboutCompany: "", questionsToAsk: "", otherNotes: "")

    func load(note: InterviewNote) {
        draft = note
    }

    func save(using dataStore: DataStore) {
        dataStore.addInterviewNote(draft)
        draft = InterviewNote(companyName: "", roleTitle: "", whyThisRole: "", whatILikeAboutCompany: "", questionsToAsk: "", otherNotes: "")
    }
}
