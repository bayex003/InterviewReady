import SwiftUI
import SwiftData

struct HomeView: View {
    @Binding var selectedTab: AppTab

    @EnvironmentObject private var jobsStore: JobsStore

    @AppStorage("userName") private var userName: String = ""
    @AppStorage("hasCompletedNamePrompt_v1") private var hasCompletedNamePrompt: Bool = false
    @State private var showNameAlert = false

    @Query private var allStories: [Story]
    @Query(filter: #Predicate<Question> { $0.isAnswered == true }) private var answeredQuestions: [Question]

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
                    .onTapGesture { showNameAlert = true }
            }

            Spacer()

            Button {
            } label: {
                Image(systemName: "bell")
                    .font(.headline)
                    .foregroundStyle(Color.ink900)
                    .padding(12)
                    .background(Color.surfaceWhite)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(Color.ink200, lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Notifications")
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
                value: "\(answeredQuestions.count)",
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

                        Text("Practice random questions with AI feedback.")
                            .font(.subheadline)
                            .foregroundStyle(Color.ink600)
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

                        Text("\(allStories.count) stories ready for STAR method")
                            .font(.subheadline)
                            .foregroundStyle(Color.ink600)
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
                ForEach(recentApplications) { application in
                    Button {
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
                                    Text(application.role)
                                        .font(.headline)
                                        .foregroundStyle(Color.ink900)

                                    Text("\(application.company) • \(application.location)")
                                        .font(.subheadline)
                                        .foregroundStyle(Color.ink600)
                                }

                                Spacer()

                                Chip(title: application.status, isSelected: true)
                            }
                        }
                    }
                    .buttonStyle(.plain)
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

    private var recentApplications: [RecentApplication] {
        if jobsStore.jobs.isEmpty {
            return RecentApplication.placeholder
        }

        return jobsStore.jobs.prefix(3).map { job in
            RecentApplication(
                role: job.roleTitle,
                company: job.companyName,
                location: job.locationDetail ?? job.locationType.rawValue,
                status: job.stage.rawValue
            )
        }
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

                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(Color.ink600)
            }
        }
    }
}

private struct RecentApplication: Identifiable {
    let id = UUID()
    let role: String
    let company: String
    let location: String
    let status: String

    var initials: String {
        let parts = company.split(separator: " ")
        let letters = parts.prefix(2).compactMap { $0.first }
        return letters.map { String($0) }.joined().uppercased()
    }

    static let placeholder: [RecentApplication] = [
        RecentApplication(role: "Product Manager", company: "TechCorp Inc.", location: "Remote", status: "Interviewing"),
        RecentApplication(role: "Senior UX Designer", company: "CreativeStudio", location: "New York", status: "Applied"),
        RecentApplication(role: "Frontend Developer", company: "FinGo", location: "London", status: "Reviewing")
    ]
}
