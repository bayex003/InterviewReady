import SwiftUI

struct InterviewNotesListView: View {
    @EnvironmentObject private var dataStore: DataStore

    var body: some View {
        List {
            Section {
                NavigationLink(destination: InterviewNoteDetailView(note: nil)) {
                    Label("Add prep note", systemImage: "plus")
                }
            }
            ForEach(dataStore.interviewNotes) { note in
                NavigationLink(destination: InterviewNoteDetailView(note: note)) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(note.companyName)
                            .font(.headline)
                        Text(note.roleTitle)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .navigationTitle("Interview Notes")
    }
}
