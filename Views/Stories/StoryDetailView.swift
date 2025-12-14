import SwiftUI

struct StoryDetailView: View {
    @Bindable var story: Story

    var body: some View {
        Form {
            Section("Details") {
                TextField("Title", text: $story.title)
                    .font(.headline)

                TextField("Category (e.g. General, Leadership)", text: $story.category)
            }

            // STAR stays, but framed as interview-ready structure
            starSection(title: "Situation", text: $story.situation, placeholder: "Where/when was this? What was happening?")
            starSection(title: "Task", text: $story.task, placeholder: "What were you responsible for? What was the goal/challenge?")
            starSection(title: "Action", text: $story.action, placeholder: "What did YOU do? Key steps, decisions, tools.")
            starSection(title: "Result", text: $story.result, placeholder: "What changed? Add impact/metrics if possible (time, quality, customer).")
        }
        .hidesFloatingTabBar()
        .navigationTitle("Edit Career Moment")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func starSection(title: String, text: Binding<String>, placeholder: String) -> some View {
        Section(header: Text(title).fontWeight(.bold)) {
            TextEditor(text: text)
                .frame(minHeight: 100)

            if text.wrappedValue.isEmpty {
                Text(placeholder)
                    .font(.caption)
                    .foregroundStyle(.gray)
            }
        }
    }
}

