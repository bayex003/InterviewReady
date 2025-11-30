import Foundation

@MainActor
final class QuestionLibraryViewModel: ObservableObject {
    func questions(from dataStore: DataStore, rolePack: RolePack? = nil, includeLocked: Bool = false, isProUnlocked: Bool) -> [InterviewQuestion] {
        dataStore.questionLibrary.filter { question in
            if let pack = rolePack {
                return question.rolePack == nil || question.rolePack == pack
            }
            if !includeLocked, let pack = question.rolePack, pack.isProOnly && !isProUnlocked {
                return false
            }
            return true
        }
    }
}
