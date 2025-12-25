import Foundation
import StoreKit
import SwiftUI

protocol EntitlementStoring {
    var isProUnlocked: Bool { get set }
}

struct UserDefaultsEntitlementStore: EntitlementStoring {
    private let key = "isProUnlocked"
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    var isProUnlocked: Bool {
        get { defaults.bool(forKey: key) }
        set { defaults.set(newValue, forKey: key) }
    }
}

@MainActor
final class PurchaseManager: ObservableObject {
    static let productId = "interviewready_pro_lifetime"

    @Published private(set) var isPro: Bool

    private let store: EntitlementStoring
    private var updatesTask: Task<Void, Never>?

    init(store: EntitlementStoring = UserDefaultsEntitlementStore()) {
        self.store = store
        self.isPro = store.isProUnlocked

        updatesTask = Task {
            await observeTransactions()
        }

        Task {
            await refreshEntitlements()
        }
    }

    deinit {
        updatesTask?.cancel()
    }

    func purchase() async {
        do {
            let product = try await fetchProduct()
            let result = try await product.purchase()

            switch result {
            case .success(let verificationResult):
                if let transaction = verifiedTransaction(from: verificationResult) {
                    await transaction.finish()
                    setProUnlocked(true)
                }
            case .userCancelled, .pending:
                break
            @unknown default:
                break
            }
        } catch {
            // Intentionally ignore errors for now to keep UI simple.
        }
    }

    func restore() async {
        do {
            try await AppStore.sync()
        } catch {
            // Ignore restore errors for now; refresh entitlements still runs.
        }

        await refreshEntitlements()
    }

    func refreshEntitlements() async {
        var hasEntitlement = false
        for await result in Transaction.currentEntitlements {
            if let transaction = verifiedTransaction(from: result), transaction.productID == Self.productId {
                hasEntitlement = true
                break
            }
        }

        if hasEntitlement {
            setProUnlocked(true)
        } else {
            isPro = store.isProUnlocked
        }
    }

    private func fetchProduct() async throws -> Product {
        let products = try await Product.products(for: [Self.productId])
        guard let product = products.first else {
            throw PurchaseError.productNotFound
        }
        return product
    }

    private func observeTransactions() async {
        for await result in Transaction.updates {
            if let transaction = verifiedTransaction(from: result), transaction.productID == Self.productId {
                await transaction.finish()
                setProUnlocked(true)
            }
        }
    }

    private func verifiedTransaction(from result: VerificationResult<Transaction>) -> Transaction? {
        switch result {
        case .verified(let transaction):
            return transaction
        case .unverified:
            return nil
        }
    }

    private func setProUnlocked(_ isUnlocked: Bool) {
        store.isProUnlocked = isUnlocked
        isPro = isUnlocked
    }
}

enum PurchaseError: Error {
    case productNotFound
}
