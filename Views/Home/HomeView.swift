import SwiftUI
import SwiftData

struct HomeView: View {
    @Binding var selectedTab: AppTab

    @EnvironmentObject private var jobsStore: JobsStore
    @EnvironmentObject private var attemptsStore: AttemptsStore
    @EnvironmentObject private var router: AppRouter

    @AppStorage("userName") private var userName: String = ""
    @AppStorage("hasCompletedNamePrompt_v1") private var hasCompletedNamePrompt: Bool = false
    @State private var showNameAlert = false

    @Query private var allStories: [Story]

    private let statCards: [HomeStat] = [
        HomeStat(title: "Applications", icon: "square.grid.2x2.fill"),
        HomeStat(title: "Stories", icon: "book.closed.fill"),
        HomeStat(title: "Practiced", icon: "checkmark.circle.fill")
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                header
                statsRow
                startPracticingSection
                storyBankCard
                recentApplicationsSection
            }
            .padding(.horizontal)
            .padding(.top, 24)
            .padding(.bottom, 120)
        }
        .navigationBarHidden(true)
        .onAppear {
            if !hasCompletedNamePrompt,
               userName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                    if !hasCompletedNamePrompt,
                       userName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        showNameAlert = true
                    }
                }
            }
        }
        .alert("Welcome!", isPresented: $showNameAlert) {
            TextField("Your Name", text: $userName)

            Button("Not now") {
                hasCompletedNamePrompt = true
            }

            Button("Save") {
                userName = userName.trimmingCharacters(in: .whitespacesAndNewlines)
                hasCompletedNamePrompt = true
            }
        } message: {
            Text("What should we call you?")
        }
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.sage100)
                    .frame(width: 48, height: 48)
                Text(initials)
                    .font(.headline)
                    .foregroundStyle(Color.ink900)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("\(greeting),")
                    .font(.subheadline)
                    .foregroundStyle(Color.ink600)

                Text(displayName)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(Color.ink900)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
                    .onTapGesture { showNameAlert = true }
            }

            Spacer()

            Button {
            } label: {
                Image(systemName: "bell")
                    .font(.headline)
                    .foregroundStyle(Color.ink900)
                    .frame(width: 44, height: 44)
                    .background(Color.surfaceWhite)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(Color.ink200, lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Notifications")
            .accessibilityHint("Opens reminder settings")
        }
    }

    private var statsRow: some View {
        HStack(spacing: 12) {
            HomeStatCard(
                title: statCards[0].title,
                value: "\(jobsStore.jobs.count)",
                icon: statCards[0].icon
            )

            HomeStatCard(
                title: statCards[1].title,
                value: "\(allStories.count)",
                icon: statCards[1].icon
            )

            HomeStatCard(
                title: statCards[2].title,
                value: "\(attemptsStore.attempts.count)",
                icon: statCards[2].icon
            )
        }
    }

    private var startPracticingSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "Start Practicing")

            CardContainer(backgroundColor: Color.sage100, cornerRadius: 22, showShadow: false) {
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.sage500)
                                .frame(width: 44, height: 44)

                            Image(systemName: "mic.fill")
                                .foregroundStyle(.white)
                        }

                        Spacer()

                        Text("NEW")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color.surfaceWhite.opacity(0.6))
                            .clipShape(Capsule())
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Mock Interview")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundStyle(Color.ink900)
                            .lineLimit(1)
                            .minimumScaleFactor(0.85)

                        Text("Practice random questions with AI feedback.")
                            .font(.subheadline)
                            .foregroundStyle(Color.ink600)
                            .lineLimit(2)
                            .minimumScaleFactor(0.9)
                    }

                    PrimaryCTAButton(title: "Start Session", systemImage: "arrow.right") {
                        selectedTab = .practice
                    }
                }
            }
        }
    }

    private var storyBankCard: some View {
        Button {
            selectedTab = .stories
        } label: {
            CardContainer {
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.sage100)
                            .frame(width: 44, height: 44)

                        Image(systemName: "book.closed.fill")
                            .foregroundStyle(Color.sage500)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Story Bank")
                            .font(.headline)
                            .foregroundStyle(Color.ink900)
                            .lineLimit(1)
                            .minimumScaleFactor(0.9)

                        Text("\(allStories.count) stories ready for STAR method")
                            .font(.subheadline)
                            .foregroundStyle(Color.ink600)
                            .lineLimit(2)
                            .minimumScaleFactor(0.9)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .foregroundStyle(Color.ink400)
                }
            }
        }
        .buttonStyle(.plain)
    }

    private var recentApplicationsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "Recent Applications")

            VStack(spacing: 12) {
                if recentApplications.isEmpty {
                    CardContainer(showShadow: false) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("No applications yet")
                                .font(.headline)
                                .foregroundStyle(Color.ink900)

                            Text("Add an application to track your progress here.")
                                .font(.subheadline)
                                .foregroundStyle(Color.ink500)
                                .lineLimit(2)
                                .minimumScaleFactor(0.9)
                        }
                    }
                } else {
                    ForEach(recentApplications) { application in
                        Button {
                            router.selectedJobID = application.id
                            selectedTab = .jobs
                        } label: {
                            CardContainer(showShadow: false) {
                                HStack(spacing: 12) {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color.sage100)
                                            .frame(width: 44, height: 44)

                                        Text(application.initials)
                                            .font(.headline)
                                            .foregroundStyle(Color.sage500)
                                    }

                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(application.roleTitle)
                                            .font(.headline)
                                            .foregroundStyle(Color.ink900)
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.85)

                                        Text("\(application.companyName) • \(application.locationDetail ?? application.locationType.rawValue)")
                                            .font(.subheadline)
                                            .foregroundStyle(Color.ink600)
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.8)
                                    }

                                    Spacer()

                                    Chip(title: application.stage.rawValue, isSelected: true)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private var displayName: String {
        let trimmed = userName.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "Friend" : trimmed
    }

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        if hour < 12 { return "Good morning" }
        if hour < 18 { return "Good afternoon" }
        return "Good evening"
    }

    private var initials: String {
        let parts = displayName.split(separator: " ")
        let letters = parts.prefix(2).compactMap { $0.first }
        if letters.isEmpty {
            return "F"
        }
        return letters.map { String($0) }.joined()
    }

    private var recentApplications: [JobApplication] {
        jobsStore.jobs
            .sorted { $0.dateApplied > $1.dateApplied }
            .prefix(3)
            .map { $0 }
    }
}

private struct HomeStat {
    let title: String
    let icon: String
}

private struct HomeStatCard: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        CardContainer(showShadow: false) {
            VStack(alignment: .leading, spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.sage100)
                        .frame(width: 36, height: 36)

                    Image(systemName: icon)
                        .font(.caption)
                        .foregroundStyle(Color.sage500)
                }

                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(Color.ink900)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(Color.ink600)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
        }
    }
}

private extension JobApplication {
    var initials: String {
        let parts = companyName.split(separator: " ")
        let letters = parts.prefix(2).compactMap { $0.first }
        return letters.map { String($0) }.joined().uppercased()
    }
}
