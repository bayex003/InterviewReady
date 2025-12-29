import SwiftUI
import SwiftData

struct LinkedStoriesView: View {
    let questionId: UUID

    @Environment(\.modelContext) private var modelContext
    @Query private var links: [QuestionStoryLink]

    init(questionId: UUID) {
        self.questionId = questionId
        _links = Query(filter: #Predicate<QuestionStoryLink> { $0.questionId == questionId })
    }

    private var linkedStories: [Story] {
        let ids = links.map(\.storyId)
        guard !ids.isEmpty else { return [] }

        let predicate = #Predicate<Story> { ids.contains($0.id) }
        let descriptor = FetchDescriptor<Story>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.lastUpdated, order: .reverse)]
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    var body: some View {
        List {
            if linkedStories.isEmpty {
                ContentUnavailableView("No linked stories", systemImage: "book")
            } else {
                ForEach(linkedStories) { story in
                    NavigationLink {
                        StoryDetailView(story: story)
                    } label: {
                        HStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(story.title)
                                    .font(.headline)
                                    .foregroundStyle(Color.ink900)

                                Text(storyTag(for: story))
                                    .font(.caption)
                                    .foregroundStyle(Color.ink500)
                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(Color.ink400)
                        }
                    }
                }
            }
        }
        .navigationTitle("Linked Stories")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func storyTag(for story: Story) -> String {
        if let firstTag = story.tags.first, !firstTag.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return firstTag
        }
        return story.category
    }
}
