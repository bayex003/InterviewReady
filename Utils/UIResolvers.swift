import SwiftUI

enum TagColorResolver {
    private struct TagPaletteEntry {
        let foreground: Color
        let background: Color
    }

    private static let palette: [TagPaletteEntry] = [
        TagPaletteEntry(foreground: .sage500, background: .sage100),
        TagPaletteEntry(foreground: .ink700, background: .ink300),
        TagPaletteEntry(foreground: .ink600, background: .ink200),
        TagPaletteEntry(foreground: .ink500, background: .ink100)
    ]

    static func color(forTag tag: String) -> Color {
        let index = paletteIndex(for: tag)
        return palette[index].foreground
    }

    static func background(forTag tag: String) -> Color {
        let index = paletteIndex(for: tag)
        return palette[index].background
    }

    private static func paletteIndex(for tag: String) -> Int {
        let normalized = tag.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !normalized.isEmpty else {
            return 0
        }
        let hashValue = stableHash(normalized)
        return Int(hashValue % UInt64(palette.count))
    }

    private static func stableHash(_ string: String) -> UInt64 {
        var hash: UInt64 = 14695981039346656037
        for byte in string.utf8 {
            hash ^= UInt64(byte)
            hash &*= 1099511628211
        }
        return hash
    }
}

enum QuestionIconResolver {
    static func symbolName(forCategory category: String, questionText: String) -> String {
        let normalizedCategory = category.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let normalizedText = questionText.lowercased()

        if containsAny(normalizedText, keywords: ["conflict", "stakeholder"]) {
            return "person.2.fill"
        }

        if containsAny(normalizedText, keywords: ["sql", "database"]) {
            return "cylinder.fill"
        }

        if containsAny(normalizedText, keywords: ["test", "qa"]) {
            return "checkmark.seal.fill"
        }

        if containsAny(normalizedText, keywords: ["deadline", "pressure"]) {
            return "clock.fill"
        }

        switch normalizedCategory {
        case "behavioural", "behavioral":
            return "bubble.left.and.bubble.right.fill"
        case "technical":
            return "chevron.left.forwardslash.chevron.right"
        case "leadership":
            return "person.2.fill"
        case "general":
            return "sparkles"
        default:
            return "questionmark.circle.fill"
        }
    }

    private static func containsAny(_ text: String, keywords: [String]) -> Bool {
        keywords.contains { text.contains($0) }
    }
}

// MARK: - Lightweight checks (comment-only)
// TagColorResolver.color(forTag: "Systems Design") should always match
// TagColorResolver.color(forTag: "systems design")
// TagColorResolver.background(forTag: "Leadership") should be the lighter pair of its color.
//
// QuestionIconResolver.symbolName(forCategory: "Behavioral", questionText: "Tell me about conflict")
// -> "person.2.fill"
// QuestionIconResolver.symbolName(forCategory: "Technical", questionText: "Explain SQL joins")
// -> "cylinder.fill"
// QuestionIconResolver.symbolName(forCategory: "Leadership", questionText: "How do you lead?")
// -> "person.2.fill"
// QuestionIconResolver.symbolName(forCategory: "General", questionText: "Any questions?")
// -> "sparkles"
