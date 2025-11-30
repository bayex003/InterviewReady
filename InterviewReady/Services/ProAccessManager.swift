import Foundation

final class ProAccessManager: ObservableObject {
    @Published var isProUnlocked: Bool {
        didSet { UserDefaults.standard.set(isProUnlocked, forKey: Self.key) }
    }

    private static let key = "isProUnlocked"

    init() {
        self.isProUnlocked = UserDefaults.standard.bool(forKey: Self.key)
    }

    func unlockPro() {
        isProUnlocked = true
    }

    func restorePurchases() {
        // Stub for future StoreKit restore
    }
}
