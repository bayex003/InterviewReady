import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var router: AppRouter

    // Allows Home to switch tabs
    @Binding var selectedTab: AppTab

    // Name prompt
    @AppStorage("userName") private var userName: String = ""
    @AppStorage("hasCompletedNamePrompt_v1") private var hasCompletedNamePrompt: Bool = false
    @State private var showNameAlert = false

    // Settings
    @State private var showSettings = false

    // DEBUG reset UI
    @State private var showResetSeedAlert = false
    @State private var showResetDoneAlert = false

    // Data
    @Query(sort: \Job.nextInterviewDate, order: .forward) private var allJobs: [Job]
    @Query private var allStories: [Story]
    @Query(filter: #Predicate<Question> { $0.isAnswered == true }) private var answeredQuestions: [Question]

    @State private var showDrill = false

    // Active jobs = everything except rejected (matches Jobs tab)
    private var activeJobs: [Job] {
        allJobs.filter { $0.stage != .rejected }
    }

    // Soonest upcoming interview
    private var nextInterviewJob: Job? {
        activeJobs
            .compactMap { job -> (Job, Date)? in
                guard let d = job.nextInterviewDate else { return nil }
                return (job, d)
            }
            .filter { $0.1 >= Date() }
            .sorted { $0.1 < $1.1 }
            .first?.0
    }

    private var isFirstRunEmpty: Bool {
        allJobs.isEmpty && allStories.isEmpty
    }

    // Dark-mode safe “primary dark” surface
    private var primaryDarkSurface: Color {
        colorScheme == .dark ? .black : Color.ink900
    }

    // Simple “today focus” copy (consistent naming)
    private var todayFocusText: String {
        if isFirstRunEmpty {
            return "Today’s focus: Add your first job"
        }
        if allStories.isEmpty {
            return "Today’s focus: Capture 1 story"
        }
        if answeredQuestions.isEmpty {
            return "Today’s focus: Answer 1 question"
        }
        return "Today’s focus: Keep momentum"
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {

                    // HEADER
                    VStack(alignment: .leading, spacing: 4) {
                        Text(Date().formatted(.dateTime.weekday(.wide).month().day()))
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(Color.ink600)
                            .textCase(.uppercase)
#if DEBUG
                            .onLongPressGesture(minimumDuration: 0.8) {
                                showResetSeedAlert = true
                            }
#endif

                        HStack {
                            Text(greeting + ",")
                                .font(.largeTitle)

                            Spacer()

                            Button {
                                showSettings = true
                            } label: {
                                Image(systemName: "gearshape")
                                    .font(.title3)
                                    .foregroundStyle(Color.ink900)
                                    .padding(10)
                                    .background(Color.surfaceWhite)
                                    .clipShape(Circle())
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Settings")
                        }
                        .foregroundStyle(Color.ink900)

                        Text(userName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Friend!" : "\(userName)!")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundStyle(Color.ink900)
                            .onTapGesture { showNameAlert = true }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                    .padding(.top, 20)

                    // TODAY FOCUS
                    Text(todayFocusText)
                        .font(.subheadline)
                        .foregroundStyle(Color.ink600)
                        .padding(.horizontal)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    // UPCOMING INTERVIEW
                    if let nextUp = nextInterviewJob, let interviewDate = nextUp.nextInterviewDate {
                        Button {
                            selectedTab = .jobs
                        } label: {
                            CardContainer {
                                VStack(alignment: .leading, spacing: 12) {
                                    HStack {
                                        Image(systemName: "calendar.badge.clock")
                                            .foregroundStyle(.red)
                                        Text("UPCOMING INTERVIEW")
                                            .font(.caption)
                                            .fontWeight(.bold)
                                            .foregroundStyle(.red)
                                        Spacer()
                                        Text(interviewDate.formatted(.relative(presentation: .named)))
                                            .font(.caption)
                                            .foregroundStyle(Color.ink600)
                                    }

                                    Text(nextUp.roleTitle)
                                        .font(.title3)
                                        .fontWeight(.bold)
                                        .foregroundStyle(Color.ink900)

                                    Text("at \(nextUp.companyName)")
                                        .font(.body)
                                        .foregroundStyle(Color.ink600)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal)
                        .accessibilityLabel("Upcoming interview, \(nextUp.roleTitle) at \(nextUp.companyName)")
                        .accessibilityHint("Opens Jobs tab")
                    }

                    // FIRST RUN HELPER
                    if isFirstRunEmpty {
                        CardContainer {
                            VStack(alignment: .leading, spacing: 16) {
                                SectionHeader(title: "Get started")

                                Text("Add your first job and capture your first story.")
                                    .font(.subheadline)
                                    .foregroundStyle(Color.ink600)

                                VStack(spacing: 12) {
                                    PrimaryCTAButton(title: "Add a Job", systemImage: nil) {
                                        selectedTab = .jobs
                                        router.presentAddJob = true
                                    }
                                    .accessibilityHint("Switches to Jobs tab and opens Add Job")

                                    Button {
                                        selectedTab = .stories
                                        router.presentAddMoment = true
                                    } label: {
                                        Text("Write a Story")
                                            .fontWeight(.bold)
                                            .padding(.vertical, 10)
                                            .frame(maxWidth: .infinity)
                                            .background(Color.clear)
                                            .foregroundStyle(Color.ink900)
                                            .overlay(Capsule().strokeBorder(Color.ink200, lineWidth: 1))
                                            .clipShape(Capsule())
                                    }
                                    .buttonStyle(.plain)
                                    .accessibilityHint("Switches to Stories tab and opens Add Story")
                                }
                            }
                        }
                        .padding(.horizontal)
                    }

                    // STATS GRID (tappable) - hidden on first run to reduce overload
                    if !isFirstRunEmpty {
                        HStack(spacing: 16) {
                            Button { selectedTab = .jobs } label: {
                                StatCard(title: "Jobs", value: "\(allJobs.count)", icon: "briefcase.fill", color: Color.sage500)
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Jobs, \(allJobs.count)")
                            .accessibilityHint("Opens Jobs tab")

                            Button { selectedTab = .stories } label: {
                                StatCard(title: "Stories", value: "\(allStories.count)", icon: "book.closed.fill", color: Color.blue)
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Stories, \(allStories.count)")
                            .accessibilityHint("Opens Stories tab")
                        }
                        .padding(.horizontal)

                        HStack(spacing: 16) {
                            Button { selectedTab = .questions } label: {
                                StatCard(title: "Answered", value: "\(answeredQuestions.count)", icon: "checkmark.circle.fill", color: Color.green)
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Answered questions, \(answeredQuestions.count)")
                            .accessibilityHint("Opens Questions tab")

                            Button { selectedTab = .jobs } label: {
                                StatCard(title: "Active Jobs", value: "\(activeJobs.count)", icon: "chart.line.uptrend.xyaxis", color: Color.orange)
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Active jobs, \(activeJobs.count)")
                            .accessibilityHint("Opens Jobs tab")
                        }
                        .padding(.horizontal)
                    }

                    // DRILL BUTTON
                    Button {
                        showDrill = true
                    } label: {
                        HStack {
                            Image(systemName: "mic.fill")
                                .font(.title2)

                            VStack(alignment: .leading) {
                                Text("Start 5-Minute Drill")
                                    .fontWeight(.bold)

                                Text(answeredQuestions.isEmpty ? "Build confidence (3 questions)" : "Keep momentum (3 random questions)")
                                    .font(.caption)
                                    .opacity(0.8)
                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                        }
                        .padding()
                        .foregroundColor(.white)
                        .background(primaryDarkSurface)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(color: Color.black.opacity(0.1), radius: 10, y: 5)
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                    .padding(.bottom, 10)
                    .accessibilityHint("Starts a short practice session")

                    // QUICK ACTIONS (below drill)
                    VStack(spacing: 12) {
                        SectionHeader(title: "Quick actions")

                        HStack(spacing: 12) {
                            PrimaryCTAButton(title: "+ Add Job", systemImage: nil) {
                                selectedTab = .jobs
                                router.presentAddJob = true
                            }
                            .accessibilityHint("Switches to Jobs tab and opens Add Job")

                            Button {
                                selectedTab = .stories
                                router.presentAddMoment = true
                            } label: {
                                Text("+ Add Story")
                                    .fontWeight(.bold)
                                    .padding(.vertical, 10)
                                    .frame(maxWidth: .infinity)
                                    .background(Color.clear)
                                    .foregroundStyle(Color.ink900)
                                    .overlay(Capsule().strokeBorder(Color.ink200, lineWidth: 1))
                                    .clipShape(Capsule())
                            }
                            .buttonStyle(.plain)
                            .accessibilityHint("Switches to Stories tab and opens Add Story")
                        }
                    }
                    .padding(.horizontal)

                    Spacer(minLength: 100)
                }
            }
            .background(Color.cream50)
            .navigationTitle("Home")
            .navigationBarHidden(true)
            .fullScreenCover(isPresented: $showDrill) {
                PracticeSessionView()
            }
            .sheet(isPresented: $showSettings) {
                SettingsView() // rename if your settings screen has a different name
            }
            .onAppear {
                // Show only once after fresh install, delay slightly so it won’t pop over splash fade
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

#if DEBUG
            .alert("Reset Seed Data?", isPresented: $showResetSeedAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Reset", role: .destructive) {
                    DataSeeder.shared.resetSeedData(modelContext: modelContext)
                    userName = ""
                    hasCompletedNamePrompt = false
                    showResetDoneAlert = true
                }
            } message: {
                Text("This will delete Jobs, Questions, and Stories, then reseed from JSON.")
            }
            .alert("Reset Complete", isPresented: $showResetDoneAlert) {
                Button("OK") { }
            } message: {
                Text("Seed data has been reset and reloaded.")
            }
#endif
        }
    }

    var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        if hour < 12 { return "Good Morning" }
        if hour < 18 { return "Good Afternoon" }
        return "Good Evening"
    }
}

// Subview for StatCard
struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(color)
                Spacer()
            }
            Text(value)
                .font(.title)
                .fontWeight(.bold)
                .foregroundStyle(Color.ink900)
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(Color.ink600)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.surfaceWhite)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color.black.opacity(0.03), radius: 5, y: 2)
    }
}
