import SwiftUI

struct StarStoriesListView: View {
    @EnvironmentObject private var dataStore: DataStore

    var body: some View {
        List {
            Section {
                NavigationLink(destination: StarStoryFormView()) {
                    Label("Create new STAR story", systemImage: "plus.circle.fill")
                }
            }
            Section(header: Text("Saved Stories")) {
                ForEach(dataStore.starStories) { story in
                    NavigationLink(destination: StarStoryDetailView(story: story)) {
                        VStack(alignment: .leading) {
                            Text(story.title)
                                .font(.headline)
                            Text(story.createdAt.formatted(date: .abbreviated, time: .omitted))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
        .navigationTitle("STAR Stories")
    }
}
