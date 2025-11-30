import SwiftUI

struct InterviewNoteDetailView: View {
    @EnvironmentObject private var dataStore: DataStore
    @StateObject private var viewModel = InterviewNotesViewModel()
    let note: InterviewNote?

    var body: some View {
        Form {
            Section(header: Text("Company")) {
                TextField("Company name", text: $viewModel.draft.companyName)
                TextField("Role title", text: $viewModel.draft.roleTitle)
                DatePicker("Interview date", selection: Binding(
                    get: { viewModel.draft.date ?? Date() },
                    set: { viewModel.draft.date = $0 }
                ), displayedComponents: .date)
            }
            Section(header: Text("Why this role")) {
                TextEditor(text: $viewModel.draft.whyThisRole).frame(minHeight: 80)
            }
            Section(header: Text("What I like about the company")) {
                TextEditor(text: $viewModel.draft.whatILikeAboutCompany).frame(minHeight: 80)
            }
            Section(header: Text("Questions to ask")) {
                TextEditor(text: $viewModel.draft.questionsToAsk).frame(minHeight: 80)
            }
            Section(header: Text("Other notes")) {
                TextEditor(text: $viewModel.draft.otherNotes).frame(minHeight: 80)
            }
            Section {
                PrimaryButton(title: "Save Note") {
                    viewModel.save(using: dataStore)
                }
            }
        }
        .navigationTitle(note == nil ? "New Note" : "Edit Note")
        .onAppear {
            if let note { viewModel.load(note: note) }
        }
    }
}
