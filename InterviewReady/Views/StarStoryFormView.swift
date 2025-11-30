import SwiftUI

struct StarStoryFormView: View {
    @EnvironmentObject private var dataStore: DataStore
    @StateObject private var viewModel = StarStoriesViewModel()

    var body: some View {
        Form {
            Section(header: Text("Title")) {
                TextField("Example: Resolved a customer issue", text: $viewModel.draft.title)
            }
            Section(header: Text("Situation"), footer: Text("Set the scene: where were you, who was involved?")) {
                TextEditor(text: $viewModel.draft.situation).frame(minHeight: 80)
            }
            Section(header: Text("Task"), footer: Text("What were you responsible for?")) {
                TextEditor(text: $viewModel.draft.task).frame(minHeight: 80)
            }
            Section(header: Text("Action"), footer: Text("What did you personally do?")) {
                TextEditor(text: $viewModel.draft.action).frame(minHeight: 80)
            }
            Section(header: Text("Result"), footer: Text("Quantify impact if possible")) {
                TextEditor(text: $viewModel.draft.result).frame(minHeight: 80)
            }
            Section {
                PrimaryButton(title: "Save Story") {
                    viewModel.save(using: dataStore)
                }
            }
        }
        .navigationTitle("New STAR Story")
    }
}
