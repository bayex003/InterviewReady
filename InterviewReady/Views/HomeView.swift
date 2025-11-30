import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var dataStore: DataStore
    @EnvironmentObject private var proManager: ProAccessManager
    @StateObject private var viewModel = HomeViewModel()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header
                quickStats
                navigationGrid
            }
            .padding()
        }
        .background(Color.irBackground.ignoresSafeArea())
        .navigationTitle("InterviewReady")
        .toolbarTitleDisplayMode(.inline)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(viewModel.welcomeMessage)
                .font(.system(.title2, design: .rounded))
                .foregroundStyle(.white)
            if !proManager.isProUnlocked {
                HStack {
                    Image(systemName: "lock.fill")
                        .foregroundColor(.yellow)
                    Text("Upgrade to Unlock All Packs")
                        .foregroundColor(.white.opacity(0.7))
                        .font(.subheadline)
                }
                .padding(12)
                .background(Color.white.opacity(0.05))
                .cornerRadius(14)
            }
        }
    }

    private var quickStats: some View {
        let stats = viewModel.quickStats(dataStore: dataStore)
        return HStack(spacing: 12) {
            statCard(title: "Answers", value: stats.answers, icon: "text.bubble")
            statCard(title: "Stories", value: stats.stories, icon: "sparkles")
            statCard(title: "Wins", value: stats.achievements, icon: "trophy")
        }
    }

    private func statCard(title: String, value: Int, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: icon)
                Spacer()
                Text("\(value)")
                    .font(.title2.bold())
            }
            Text(title)
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.white.opacity(0.08))
        .cornerRadius(16)
    }

    private var navigationGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
            NavigationLink(destination: DailyQuestionView()) {
                CardView(title: "Daily Question", subtitle: "Answer today's prompt", icon: "sun.max.fill") {
                    TagChipView(text: "Fresh daily", color: .irMint)
                }
            }
            NavigationLink(destination: MyAnswersView()) {
                CardView(title: "My Answers", subtitle: "Vault of your responses", icon: "text.badge.plus") {
                    Text("Review, edit, and favourite")
                        .font(.footnote)
                        .foregroundColor(.white.opacity(0.7))
                }
            }
            NavigationLink(destination: StarStoriesListView()) {
                CardView(title: "STAR Stories", subtitle: "Craft strong stories", icon: "sparkle") {
                    Text("Structure: Situation, Task, Action, Result")
                        .font(.footnote)
                        .foregroundColor(.white.opacity(0.7))
                }
            }
            NavigationLink(destination: AchievementsListView()) {
                CardView(title: "Achievements", subtitle: "Track your wins", icon: "trophy.fill") {
                    Text("Remember results and metrics")
                        .font(.footnote)
                        .foregroundColor(.white.opacity(0.7))
                }
            }
            NavigationLink(destination: QuestionLibraryView()) {
                CardView(title: "Question Library", subtitle: "Templates & examples", icon: "books.vertical") {
                    Text("Browse common questions")
                        .font(.footnote)
                        .foregroundColor(.white.opacity(0.7))
                }
            }
            NavigationLink(destination: RolePacksView()) {
                CardView(title: "Role Packs", subtitle: "Tailored collections", icon: "briefcase.fill") {
                    HStack {
                        TagChipView(text: "Free")
                        TagChipView(text: "Pro", color: .yellow)
                    }
                }
            }
            NavigationLink(destination: InterviewNotesListView()) {
                CardView(title: "Interview Notes", subtitle: "Company research", icon: "note.text") {
                    Text("Prep per company")
                        .font(.footnote)
                        .foregroundColor(.white.opacity(0.7))
                }
            }
        }
    }
}
