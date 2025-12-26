import SwiftUI
import SwiftData

struct StoriesListView: View {
    @Query(sort: \Story.title) private var stories: [Story]
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var router: AppRouter
    @EnvironmentObject private var purchaseManager: PurchaseManager

    @State private var searchText = ""
    @State private var showAddStory = false
    @State private var showPaywall = false

    // MARK: - V2 Free Limit (Stories)
    private let freeStoryLimit = 10

    private var hasReachedFreeLimit: Bool {
        !purchaseManager.isPro && stories.count >= freeStoryLimit
    }

    private var filteredStories: [Story] {
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

                        Text("No Stories Yet")
                            .font(.headline)
                            .foregroundStyle(Color.ink900)

                        Text("Capture moments using STAR so you can reuse them in interviews.")
                            .font(.subheadline)
                            .foregroundStyle(Color.ink600)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)

                        Button {
                            handleAddTapped()
                        } label: {
                            Text("Write a Story")
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
            .navigationTitle("Stories")
            .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always))
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        handleAddTapped()
                    } label: {
                        Image(systemName: "plus")
                            .foregroundStyle(Color.ink900)
                    }
                }
            }
            .sheet(isPresented: $showAddStory) {
                AddStoryView()
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView()
                    .environmentObject(purchaseManager)
            }
            .tapToDismissKeyboard()
            .navigationDestination(item: $selectedStory) { story in
                StoryDetailView(story: story)
            }
            .onChange(of: router.presentAddMoment) { _, newValue in
                if newValue {
                    handleAddTapped()
                    router.presentAddMoment = false
                }
            }
        }
    }

    // MARK: - Navigation
    @State private var selectedStory: Story?

    // MARK: - Add gating
    private func handleAddTapped() {
        if hasReachedFreeLimit {
            showPaywall = true
        } else {
            showAddStory = true
        }
    }

    // MARK: - Delete
    private func deleteStory(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(filteredStories[index])
            }
        }
    }
}

