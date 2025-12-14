import SwiftUI
import SwiftData

struct StoriesListView: View {
    @Query(sort: \Story.title) private var stories: [Story]
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var router: AppRouter


    @State private var searchText = ""
    @State private var showAddStory = false

    var filteredStories: [Story] {
        let s = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !s.isEmpty else { return stories }
        return stories.filter { $0.title.localizedCaseInsensitiveContains(s) }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.cream50.ignoresSafeArea()

                if stories.isEmpty {
                    // ACTIONABLE EMPTY STATE
                    VStack(spacing: 16) {
                        Image(systemName: "book.closed")
                            .font(.system(size: 60))
                            .foregroundStyle(Color.sage100)

                        Text("No Career Moments Yet")
                            .font(.headline)
                            .foregroundStyle(Color.ink900)

                        Text("Capture moments using STAR so you can reuse them in interviews.")
                            .font(.subheadline)
                            .foregroundStyle(Color.ink600)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)

                        Button {
                            showAddStory = true
                        } label: {
                            Text("Write a Moment")
                                .fontWeight(.bold)
                                .padding()
                                .padding(.horizontal, 12)
                                .background(Color.sage500)
                                .foregroundColor(.white)
                                .clipShape(Capsule())
                        }
                        .padding(.top, 8)
                    }
                } else {
                    // LIST (no accessory duplication)
                    List {
                        ForEach(filteredStories) { story in
                            Button {
                                // Navigation via value (below) avoids odd accessory behaviour
                                selectedStory = story
                            } label: {
                                StoryRow(story: story)
                            }
                            .buttonStyle(.plain)
                            .listRowBackground(Color.surfaceWhite)
                        }
                        .onDelete(perform: deleteStory)
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Career Moments")
            .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always))
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showAddStory = true } label: {
                        Image(systemName: "plus")
                            .foregroundStyle(Color.ink900)
                    }
                }
            }
            .sheet(isPresented: $showAddStory) {
                AddStoryView()
            }
            .tapToDismissKeyboard()
            .navigationDestination(item: $selectedStory) { story in
                StoryDetailView(story: story)
            }
            .onChange(of: router.presentAddMoment) { _, newValue in
                if newValue {
                    showAddStory = true
                    router.presentAddMoment = false
                }
            }
        }
    }

    // MARK: - Navigation
    @State private var selectedStory: Story?

    // MARK: - Delete
    private func deleteStory(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(filteredStories[index])
            }
        }
    }
}
