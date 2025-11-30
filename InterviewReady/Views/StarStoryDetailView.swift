import SwiftUI

struct StarStoryDetailView: View {
    let story: StarStory

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                storySection(title: "Situation", text: story.situation)
                storySection(title: "Task", text: story.task)
                storySection(title: "Action", text: story.action)
                storySection(title: "Result", text: story.result)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Narrative")
                        .font(.headline)
                    Text(story.assembledNarrative)
                        .padding()
                        .background(Color.white.opacity(0.05))
                        .cornerRadius(14)
                }
                Spacer()
            }
            .padding()
        }
        .navigationTitle(story.title)
        .background(Color.irBackground.ignoresSafeArea())
    }

    private func storySection(title: String, text: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.headline)
            Text(text)
                .foregroundColor(.white.opacity(0.85))
                .padding()
                .background(Color.white.opacity(0.05))
                .cornerRadius(12)
        }
    }
}
