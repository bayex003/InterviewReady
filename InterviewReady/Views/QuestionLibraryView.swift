import SwiftUI

struct QuestionLibraryView: View {
    @EnvironmentObject private var dataStore: DataStore
    @EnvironmentObject private var proManager: ProAccessManager
    @StateObject private var viewModel = QuestionLibraryViewModel()

    var body: some View {
        List {
            ForEach(QuestionCategory.allCases) { category in
                Section(header: Text(category.rawValue)) {
                    ForEach(viewModel.questions(from: dataStore, isProUnlocked: proManager.isProUnlocked).filter { $0.category == category }) { question in
                        NavigationLink(destination: QuestionDetailView(question: question)) {
                            VStack(alignment: .leading, spacing: 6) {
                                Text(question.text)
                                if let pack = question.rolePack {
                                    TagChipView(text: pack.name, color: pack.isProOnly ? .yellow : .irMint)
                                }
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Question Library")
    }
}
