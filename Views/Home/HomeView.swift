import SwiftUI
import SwiftData

struct HomeView: View {
    @Binding var selectedTab: AppTab

    @EnvironmentObject private var attemptsStore: AttemptsStore
    //@EnvironmentObject private var router: AppRouter  // Removed to stabilise build

    @AppStorage("userName") private var userName: String = ""
    @AppStorage("hasCompletedNamePrompt_v1") private var hasCompletedNamePrompt: Bool = false
    @State private var showNameAlert = false
    @State private var showStartDrillSheet = false

    @Query private var allStories: [Story]
    @Query(sort: \Job.dateApplied, order: .reverse) private var allJobs: [Job]

    private let statCards: [HomeStat] = [
        HomeStat(title: "Applications", icon: "square.grid.2x2.fill"),
        HomeStat(title: "Stories", icon: "book.closed.fill"),
        HomeStat(title: "Practised", icon: "checkmark.circle.fill")
    ]

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 18) {
                header

                statsRow

                sectionDivider

                startPractisingSection

                storyBankCard

                sectionDivider

                recentApplicationsSection
            }
            .padding(.horizontal)
            .padding(.top, 24)
            .padding(.bottom, 120)
        }
        .background(Color.cream50.ignoresSafeArea())
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
            TextField("Your name", text: $userName)

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
        .sheet(isPresented: $showStartDrillSheet) {
            StartDrillSheet()
        }
    }

    private var sectionDivider: some View {
        Divider()
            .overlay(Color.ink200.opacity(0.7))
            .padding(.vertical, 2)
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

            NavigationLink {
                SettingsView()
            } label: {
                Image(systemName: "gearshape")
                    .font(.headline)
                    .foregroundStyle(Color.ink900)
                    .frame(width: 44, height: 44)
                    .background(Color.surfaceWhite)
                    .clipShape(Circle())
                    .overlay(
                        Circle().stroke(Color.ink200, lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Settings")
        }
    }

    // ✅ FIX: Always 3 equal-width cards across the screen
    private var statsRow: some View {
        GeometryReader { geo in
            let totalSpacing: CGFloat = 12 * 2
            let cardWidth = (geo.size.width - totalSpacing) / 3

            HStack(spacing: 12) {
                HomeStatCard(
                    title: statCards[0].title,
                    value: "\(allJobs.count)",
                    icon: statCards[0].icon
                )
                .frame(width: cardWidth)

                HomeStatCard(
                    title: statCards[1].title,
                    value: "\(allStories.count)",
                    icon: statCards[1].icon
                )
                .frame(width: cardWidth)

                HomeStatCard(
                    title: statCards[2].title,
                    value: "\(attemptsStore.attempts.count)",
                    icon: statCards[2].icon
                )
                .frame(width: cardWidth)
            }
        }
        .frame(height: 110)
    }

    private var startPractisingSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader(title: "Start Practising", actionTitle: "") { }

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
                        Text("Interview Drill")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundStyle(Color.ink900)
                            .lineLimit(1)
                            .minimumScaleFactor(0.85)

                        Text("Practise three random questions to build confidence and improve delivery.")
                            .font(.subheadline)
                            .foregroundStyle(Color.ink600)
                            .lineLimit(2)
                            .minimumScaleFactor(0.9)
                    }

                    // ✅ Use the simplest PrimaryCTAButton signature to avoid init mismatch errors
                    PrimaryCTAButton("Start Session") {
                        showStartDrillSheet = true
                    }
                }
            }
        }
    }

    private var storyBankCard: some View {
        Button {
            selectedTab = .stories
        } label: {
            CardContainer(showShadow: false) {
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
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader(title: "Recent Applications", actionTitle: "") { }

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

                                        Text("\(application.companyName) • \((application.location ?? "Saved"))")
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
        if letters.isEmpty { return "F" }
        return letters.map { String($0) }.joined()
    }

    private var recentApplications: [Job] {
        allJobs.prefix(3).map { $0 }
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
        .frame(height: 110)
    }
}

private extension Job {
    var initials: String {
        let parts = companyName.split(separator: " ")
        let letters = parts.prefix(2).compactMap { $0.first }
        return letters.map { String($0) }.joined().uppercased()
    }
}
