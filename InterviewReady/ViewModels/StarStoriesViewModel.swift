import Foundation

@MainActor
final class StarStoriesViewModel: ObservableObject {
    @Published var draft = StarStory(title: "", situation: "", task: "", action: "", result: "")

    func load(story: StarStory) {
        draft = story
    }

    func save(using dataStore: DataStore) {
        dataStore.addStarStory(draft)
        draft = StarStory(title: "", situation: "", task: "", action: "", result: "")
    }
}
