import SwiftUI

struct AchievementFormView: View {
    @EnvironmentObject private var dataStore: DataStore
    @StateObject private var viewModel = AchievementsViewModel()

    var body: some View {
        Form {
            Section(header: Text("Title")) {
                TextField("Launched new process", text: $viewModel.draft.title)
            }
            Section(header: Text("Description")) {
                TextEditor(text: $viewModel.draft.description)
                    .frame(minHeight: 120)
            }
            Section(header: Text("Impact (optional)")) {
                TextField("Saved 3 hours/week", text: Binding(
                    get: { viewModel.draft.impact ?? "" },
                    set: { viewModel.draft.impact = $0.isEmpty ? nil : $0 }
                ))
            }
            Section {
                PrimaryButton(title: "Save Achievement") {
                    viewModel.save(using: dataStore)
                }
            }
        }
        .navigationTitle("Achievement")
    }
}
