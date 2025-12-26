import Foundation
import SwiftData

@MainActor
final class AppDataController: ObservableObject {
    @Published var container: ModelContainer?
    @Published var loadError: String?
    @Published var isUsingCloud = false

    private let schema = Schema([Job.self, Question.self, Story.self, PracticeAttempt.self])
    private let proKey = "isProUnlocked"

    func loadInitialContainer() async {
        loadError = nil
        if UserDefaults.standard.bool(forKey: proKey) {
            await switchToCloudIfPro()
            if container == nil {
                await loadLocalContainer()
            }
        } else {
            await loadLocalContainer()
        }
    }

    func switchToCloudIfPro() async {
        guard UserDefaults.standard.bool(forKey: proKey) else { return }
        if isUsingCloud { return }

        do {
            let localContainer = try makeLocalContainer()
            let cloudContainer = try makeCloudContainer()

            if try await isStoreEmpty(context: cloudContainer.mainContext) {
                try await migrateLocalDataToCloud(
                    localContext: localContainer.mainContext,
                    cloudContext: cloudContainer.mainContext
                )
            }

            container = cloudContainer
            isUsingCloud = true
            DataSeeder.shared.seedDataIfNeeded(modelContext: cloudContainer.mainContext)
        } catch {
            loadError = "iCloud Sync isn’t available right now. Continuing with local data."
            await loadLocalContainer()
        }
    }

    func switchToLocalIfNeeded() async {
        if !UserDefaults.standard.bool(forKey: proKey) || isUsingCloud {
            await loadLocalContainer()
        }
    }

    private func loadLocalContainer() async {
        do {
            let localContainer = try makeLocalContainer()
            container = localContainer
            isUsingCloud = false
            DataSeeder.shared.seedDataIfNeeded(modelContext: localContainer.mainContext)
        } catch {
            loadError = error.localizedDescription
        }
    }

    private func makeLocalContainer() throws -> ModelContainer {
        let configuration = try ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            url: storeURL(filename: "InterviewReady_local.store")
        )
        return try ModelContainer(for: schema, configurations: [configuration])
    }

    private func makeCloudContainer() throws -> ModelContainer {
        let configuration = try ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            url: storeURL(filename: "InterviewReady_cloud.store"),
            cloudKitDatabase: .automatic
        )
        return try ModelContainer(for: schema, configurations: [configuration])
    }

    private func storeURL(filename: String) throws -> URL {
        let baseURL = try FileManager.default.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        return baseURL.appendingPathComponent(filename)
    }

    private func isStoreEmpty(context: ModelContext) async throws -> Bool {
        let jobCount = try context.fetchCount(FetchDescriptor<Job>())
        let storyCount = try context.fetchCount(FetchDescriptor<Story>())
        let questionCount = try context.fetchCount(FetchDescriptor<Question>())
        let attemptCount = try context.fetchCount(FetchDescriptor<PracticeAttempt>())
        return jobCount + storyCount + questionCount + attemptCount == 0
    }

    private func migrateLocalDataToCloud(
        localContext: ModelContext,
        cloudContext: ModelContext
    ) async throws {
        let localJobs = try localContext.fetch(FetchDescriptor<Job>())
        let localStories = try localContext.fetch(FetchDescriptor<Story>())
        let localQuestions = try localContext.fetch(FetchDescriptor<Question>())
        let localAttempts = try localContext.fetch(FetchDescriptor<PracticeAttempt>())

        for job in localJobs {
            let newJob = Job(companyName: job.companyName, roleTitle: job.roleTitle, stage: job.stage)
            newJob.dateApplied = job.dateApplied
            newJob.nextInterviewDate = job.nextInterviewDate
            newJob.generalNotes = job.generalNotes
            cloudContext.insert(newJob)
        }

        for story in localStories {
            let newStory = Story(title: story.title, category: story.category)
            newStory.id = story.id
            newStory.situation = story.situation
            newStory.task = story.task
            newStory.action = story.action
            newStory.result = story.result
            newStory.dateAdded = story.dateAdded
            cloudContext.insert(newStory)
        }

        for question in localQuestions {
            let newQuestion = Question(
                text: question.text,
                category: question.category,
                tip: question.tip,
                exampleAnswer: question.exampleAnswer
            )
            newQuestion.id = question.id
            newQuestion.isAnswered = question.isAnswered
            newQuestion.answerText = question.answerText
            newQuestion.dateAdded = question.dateAdded
            newQuestion.dateAnswered = question.dateAnswered
            cloudContext.insert(newQuestion)
        }

        for attempt in localAttempts {
            let newAttempt = PracticeAttempt(
                source: attempt.source,
                questionTextSnapshot: attempt.questionTextSnapshot,
                questionId: attempt.questionId,
                durationSeconds: attempt.durationSeconds,
                createdAt: attempt.createdAt,
                confidence: attempt.confidence,
                notes: attempt.notes
            )
            newAttempt.id = attempt.id
            cloudContext.insert(newAttempt)
        }

        try cloudContext.save()
    }
}
