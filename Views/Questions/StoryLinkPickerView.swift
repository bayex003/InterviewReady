import SwiftUI
import SwiftData

struct StoryLinkPickerView: View {
    let onSave: (Set<UUID>) -> Void

    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Story.lastUpdated, order: .reverse) private var stories: [Story]

    @State private var selection: Set<UUID>

    init(initialSelection: Set<UUID>, onSave: @escaping (Set<UUID>) -> Void) {
        self.onSave = onSave
        _selection = State(initialValue: initialSelection)
    }

    var body: some View {
        NavigationStack {
            List {
                if stories.isEmpty {
                    ContentUnavailableView("No stories yet", systemImage: "book")
                } else {
                    ForEach(stories) { story in
                        Button {
                            toggleSelection(for: story)
                        } label: {
                            HStack(spacing: 12) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(story.title)
                                        .font(.headline)
                                        .foregroundStyle(Color.ink900)

                                    Text(story.category)
                                        .font(.caption)
                                        .foregroundStyle(Color.ink500)
                                }

                                Spacer()

                                if selection.contains(story.id) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(Color.sage500)
                                } else {
                                    Image(systemName: "circle")
                                        .foregroundStyle(Color.ink300)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .navigationTitle("Link Stories")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(selection)
                        dismiss()
                    }
                }
            }
        }
    }

    private func toggleSelection(for story: Story) {
        if selection.contains(story.id) {
            selection.remove(story.id)
        } else {
            selection.insert(story.id)
        }
    }
}
