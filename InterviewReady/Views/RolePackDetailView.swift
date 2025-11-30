import SwiftUI

struct RolePackDetailView: View {
    @EnvironmentObject private var dataStore: DataStore
    @EnvironmentObject private var proManager: ProAccessManager
    let pack: RolePack
    @StateObject private var viewModel = QuestionLibraryViewModel()

    var body: some View {
        List {
            ForEach(viewModel.questions(from: dataStore, rolePack: pack, includeLocked: true, isProUnlocked: proManager.isProUnlocked)) { question in
                NavigationLink(destination: QuestionDetailView(question: question)) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(question.text)
                        Text(question.category.rawValue)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .navigationTitle(pack.name)
    }
}
