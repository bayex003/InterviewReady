import Foundation

struct DrillTipsEngine {
    private let actionVerbs = [
        "led", "built", "fixed", "improved", "delivered", "analysed", "designed", "owned"
    ]

    func tips(for answer: String) -> [String] {
        let trimmed = answer.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }
        let lowercased = trimmed.lowercased()

        var tips: [String] = []

        if trimmed.count < 200 {
            tips.append("Add more detail: what did you do, and what changed?")
        }

        if !containsNumber(in: trimmed) {
            tips.append("Add a measurable result (%, £, time saved).")
        }

        if !containsActionVerb(in: trimmed) {
            tips.append("Start sentences with action verbs.")
        }

        if containsWord("we", in: lowercased) && !containsWord("i", in: lowercased) {
            tips.append("Make your contribution clear: use ‘I’ for your actions.")
        }

        return Array(tips.prefix(4))
    }

    private func containsNumber(in text: String) -> Bool {
        text.range(of: "\\d", options: .regularExpression) != nil
    }

    private func containsActionVerb(in text: String) -> Bool {
        let lowercased = text.lowercased()
        return actionVerbs.contains { verb in
            containsWord(verb, in: lowercased)
        }
    }

    private func containsWord(_ word: String, in text: String) -> Bool {
        let pattern = "\\b\(NSRegularExpression.escapedPattern(for: word))\\b"
        return text.range(of: pattern, options: .regularExpression) != nil
    }
}
