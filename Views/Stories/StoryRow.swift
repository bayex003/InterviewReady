import SwiftUI

struct StoryRow: View {
    let story: Story

    var body: some View {
        HStack(spacing: 12) {
            // Leading icon
            Image(systemName: "book.closed")
                .foregroundStyle(Color.sage100)
                .imageScale(.large)

            VStack(alignment: .leading, spacing: 4) {
                Text(story.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Untitled" : story.title)
                    .font(.headline)
                    .foregroundStyle(Color.ink900)
                    .lineLimit(1)

                // Single-line meta to prevent weird wrapping
                let category = story.category.trimmingCharacters(in: .whitespacesAndNewlines)
                let meta = category.isEmpty
                    ? "Added \(story.dateAdded.formatted(.relative(presentation: .named)))"
                    : "\(category) • Added \(story.dateAdded.formatted(.relative(presentation: .named)))"

                Text(meta)
                    .font(.subheadline)
                    .foregroundStyle(Color.ink600)
                    .lineLimit(1)
            }

            Spacer()

            // Single custom chevron (since we’re not using NavigationLink row accessory)
            Image(systemName: "chevron.right")
                .foregroundStyle(Color.ink400)
                .imageScale(.small)
        }
        .padding(.vertical, 8)
    }
}

#Preview("StoryRow") {
    let sample = Story(title: "Database Migration Crisis", category: "Problem Solving")
    StoryRow(story: sample)
        .padding()
        .background(Color.surfaceWhite)
}
