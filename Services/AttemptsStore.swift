import Foundation
import Combine
import SwiftUI

@MainActor
final class AttemptsStore: ObservableObject {
    let objectWillChange = ObservableObjectPublisher()
    
    @Published private(set) var attempts: [Attempt] = []

    private let defaults: UserDefaults
    private let storageKey = "attempts_store_v1"
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        self.encoder = encoder

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        self.decoder = decoder

        if let data = defaults.data(forKey: storageKey),
           let loaded = try? decoder.decode([Attempt].self, from: data) {
            self.attempts = loaded.sorted { $0.timestamp > $1.timestamp }
        } else {
            self.attempts = []
        }
    }

    func add(_ newAttempts: [Attempt]) {
        guard !newAttempts.isEmpty else { return }
        attempts = (newAttempts + attempts)
            .sorted { $0.timestamp > $1.timestamp }
        persist()
    }

    func delete(_ attempt: Attempt) {
        attempts.removeAll { $0.id == attempt.id }
        persist()
    }

    func delete(at offsets: IndexSet) {
        attempts.remove(atOffsets: offsets)
        persist()
    }

    private func persist() {
        do {
            let data = try encoder.encode(attempts)
            defaults.set(data, forKey: storageKey)
        } catch {
            defaults.removeObject(forKey: storageKey)
        }
    }
}
