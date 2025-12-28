import SwiftUI

struct StoryDetailView: View {
    @Bindable var story: Story

    var body: some View {
        NewStoryView(story: story)
    }
}
