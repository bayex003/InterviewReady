import Foundation

struct StoryStore {
    let stories: [Story]

    var allTags: [String] {
        StoryStore.sortedTags(stories.flatMap { $0.tags })
    }

    static func sortedTags(_ tags: [String]) -> [String] {
        normalizeTags(tags).sorted { lhs, rhs in
            lhs.localizedCaseInsensitiveCompare(rhs) == .orderedAscending
        }
    }

    static func normalizeTags(_ tags: [String]) -> [String] {
        var seen = Set<String>()
        var results: [String] = []

        for tag in tags {
            let trimmed = tag.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { continue }
            let key = trimmed.lowercased()
            guard !seen.contains(key) else { continue }
            seen.insert(key)
            results.append(trimmed)
        }

        return results
    }
}
