import Foundation
import SwiftData

// Data Structures matching your JSON
struct InitialQuestionData: Decodable {
    let text: String
    let category: String

    // NEW (optional)
    let tip: String?
    let exampleAnswer: String?
}

struct InitialStoryData: Decodable {
    let title: String
    let category: String
    let situation: String
    let task: String
    let action: String
    let result: String
}

final class DataSeeder {
    static let shared = DataSeeder()

    // Increment this version number if you ever want to force-reseed data in a future update
    private let seedKey = "hasSeededData_v1"

    private init() {}

    @MainActor
    func seedDataIfNeeded(modelContext: ModelContext) {
        if !isStoreEmpty(modelContext: modelContext) { return }

        print("🌱 Seeding initial data...")
        seedQuestions(context: modelContext)
        seedStories(context: modelContext)
        seedJobs(context: modelContext)

        do {
            try modelContext.save()
            UserDefaults.standard.set(true, forKey: seedKey)
            print("✅ Seeding complete.")
        } catch {
            print("❌ Failed to save seeded data: \(error)")
        }
    }

    @MainActor
    private func isStoreEmpty(modelContext: ModelContext) -> Bool {
        do {
            let jobs = try modelContext.fetchCount(FetchDescriptor<Job>())
            let stories = try modelContext.fetchCount(FetchDescriptor<Story>())
            let questions = try modelContext.fetchCount(FetchDescriptor<Question>())
            return jobs + stories + questions == 0
        } catch {
            print("⚠️ Failed to check store contents: \(error)")
            return false
        }
    }

    // MARK: - Questions

    @MainActor
    private func seedQuestions(context: ModelContext) {
        guard let url = Bundle.main.url(forResource: "initial_questions", withExtension: "json") else {
            print("⚠️ Missing initial_questions.json in app bundle (check Target Membership).")
            return
        }

        do {
            let data = try Data(contentsOf: url)
            let items = try JSONDecoder().decode([InitialQuestionData].self, from: data)

            for item in items {
                let q = Question(
                    text: item.text,
                    category: item.category,
                    isCustom: false,
                    tip: item.tip?.trimmingCharacters(in: .whitespacesAndNewlines),
                    exampleAnswer: item.exampleAnswer?.trimmingCharacters(in: .whitespacesAndNewlines)
                )
                context.insert(q)
            }

            print("✅ Seeded \(items.count) questions")
        } catch {
            print("❌ Error seeding questions: \(error)")
        }
    }

    // MARK: - Stories

    @MainActor
    private func seedStories(context: ModelContext) {
        guard let url = Bundle.main.url(forResource: "initial_stories", withExtension: "json") else {
            print("⚠️ Missing initial_stories.json in app bundle (check Target Membership).")
            return
        }

        do {
            let data = try Data(contentsOf: url)
            let items = try JSONDecoder().decode([InitialStoryData].self, from: data)

            for item in items {
                let s = Story(title: item.title, category: item.category)
                s.situation = item.situation
                s.task = item.task
                s.action = item.action
                s.result = item.result
                context.insert(s)
            }

            print("✅ Seeded \(items.count) career moments")
        } catch {
            print("❌ Error seeding stories: \(error)")
        }
    }

    // MARK: - Sample Job

    @MainActor
    private func seedJobs(context: ModelContext) {
        let job = Job(companyName: "Tech Corp (Example)", roleTitle: "Product Designer")
        job.stage = .saved
        job.generalNotes = "This is a sample job to get you started. You can edit or delete it!"
        context.insert(job)

        print("✅ Seeded 1 sample job")
    }

    // MARK: - DEBUG: Reset (dev convenience)

    #if DEBUG
    /// Deletes all Jobs, Questions, and Stories, clears the seed flag,
    /// then immediately reseeds from JSON + sample job.
    @MainActor
    func resetSeedData(modelContext: ModelContext) {
        do {
            let jobs = try modelContext.fetch(FetchDescriptor<Job>())
            for item in jobs { modelContext.delete(item) }

            let questions = try modelContext.fetch(FetchDescriptor<Question>())
            for item in questions { modelContext.delete(item) }

            let stories = try modelContext.fetch(FetchDescriptor<Story>())
            for item in stories { modelContext.delete(item) }

            try modelContext.save()
            UserDefaults.standard.removeObject(forKey: seedKey)

            print("🧹 Reset complete. Reseeding…")
            seedDataIfNeeded(modelContext: modelContext)
        } catch {
            print("❌ Reset failed: \(error)")
        }
    }
    #endif
}
