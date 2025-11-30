import SwiftUI

struct AchievementsListView: View {
    @EnvironmentObject private var dataStore: DataStore

    var body: some View {
        List {
            Section {
                NavigationLink(destination: AchievementFormView()) {
                    Label("Add achievement", systemImage: "plus")
                }
            }
            ForEach(dataStore.achievements) { achievement in
                VStack(alignment: .leading, spacing: 6) {
                    Text(achievement.title)
                        .font(.headline)
                    Text(achievement.description)
                        .font(.subheadline)
                    HStack {
                        if let impact = achievement.impact { TagChipView(text: impact, color: .irMint) }
                        Spacer()
                        Text(achievement.date.formatted(date: .abbreviated, time: .omitted))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .navigationTitle("Achievements")
    }
}
