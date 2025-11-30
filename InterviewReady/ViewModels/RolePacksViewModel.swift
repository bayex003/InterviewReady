import Foundation

@MainActor
final class RolePacksViewModel: ObservableObject {
    func availablePacks(in dataStore: DataStore) -> [RolePack] {
        dataStore.rolePacks
    }
}
