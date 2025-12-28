import Foundation

struct StarDraft: Equatable {
    var situation: String
    var task: String
    var action: String
    var result: String

    static var empty: StarDraft {
        .init(situation: "", task: "", action: "", result: "")
    }

    static func from(scannedText: String) -> StarDraft {
        // Simple heuristic: leave empty by default (your existing ScanReview flow can populate later)
        // You can replace this with your splitter logic if you already have one elsewhere.
        .empty
    }
}
