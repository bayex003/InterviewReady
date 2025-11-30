import Foundation
import SwiftUI

@MainActor
final class DataStore: ObservableObject {
    @Published var userAnswers: [UserAnswer] = [] {
        didSet { save(userAnswers, key: .answers) }
    }
    @Published var starStories: [StarStory] = [] {
        didSet { save(starStories, key: .starStories) }
    }
    @Published var achievements: [Achievement] = [] {
        didSet { save(achievements, key: .achievements) }
    }
    @Published var interviewNotes: [InterviewNote] = [] {
        didSet { save(interviewNotes, key: .interviewNotes) }
    }

    let questionLibrary: [InterviewQuestion]
    let rolePacks: [RolePack]
    let dailyQuestions: [InterviewQuestion]

    init() {
        self.rolePacks = DataStore.seedRolePacks
        self.questionLibrary = DataStore.seedQuestions
        self.dailyQuestions = DataStore.dailyRotation
        load()
    }

    // MARK: - Daily question helpers
    func todaysQuestion() -> InterviewQuestion {
        let calendar = Calendar.current
        let dayOfYear = calendar.ordinality(of: .day, in: .year, for: Date()) ?? 0
        let index = dayOfYear % max(dailyQuestions.count, 1)
        return dailyQuestions[index]
    }

    func answerForToday() -> UserAnswer? {
        let today = Calendar.current.startOfDay(for: Date())
        return userAnswers.first { answer in
            let answerDay = Calendar.current.startOfDay(for: answer.updatedAt)
            return answerDay == today && answer.questionID == todaysQuestion().id
        }
    }

    func saveDailyAnswer(text: String) {
        let question = todaysQuestion()
        if var existing = answerForToday() {
            existing.answerText = text
            existing.updatedAt = Date()
            if let idx = userAnswers.firstIndex(where: { $0.id == existing.id }) {
                userAnswers[idx] = existing
            }
        } else {
            let newAnswer = UserAnswer(questionID: question.id, answerText: text, category: question.category)
            userAnswers.append(newAnswer)
        }
    }

    // MARK: - CRUD helpers
    func addOrUpdateAnswer(_ answer: UserAnswer) {
        if let index = userAnswers.firstIndex(where: { $0.id == answer.id }) {
            userAnswers[index] = answer
        } else {
            userAnswers.append(answer)
        }
    }

    func toggleFavourite(answer: UserAnswer) {
        guard let index = userAnswers.firstIndex(where: { $0.id == answer.id }) else { return }
        var updated = answer
        updated.isFavourite.toggle()
        updated.updatedAt = Date()
        userAnswers[index] = updated
    }

    func addStarStory(_ story: StarStory) {
        if let index = starStories.firstIndex(where: { $0.id == story.id }) {
            starStories[index] = story
        } else {
            starStories.append(story)
        }
    }

    func addAchievement(_ achievement: Achievement) {
        if let index = achievements.firstIndex(where: { $0.id == achievement.id }) {
            achievements[index] = achievement
        } else {
            achievements.append(achievement)
        }
    }

    func addInterviewNote(_ note: InterviewNote) {
        if let index = interviewNotes.firstIndex(where: { $0.id == note.id }) {
            interviewNotes[index] = note
        } else {
            interviewNotes.append(note)
        }
    }

    // MARK: - Persistence
    private enum StorageKey: String {
        case answers, starStories, achievements, interviewNotes
    }

    private let defaults = UserDefaults.standard
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    private func save<T: Codable>(_ value: T, key: StorageKey) {
        if let data = try? encoder.encode(value) {
            defaults.set(data, forKey: key.rawValue)
        }
    }

    private func load() {
        decoder.dateDecodingStrategy = .iso8601
        encoder.dateEncodingStrategy = .iso8601

        if let data = defaults.data(forKey: StorageKey.answers.rawValue), let decoded = try? decoder.decode([UserAnswer].self, from: data) {
            userAnswers = decoded
        }
        if let data = defaults.data(forKey: StorageKey.starStories.rawValue), let decoded = try? decoder.decode([StarStory].self, from: data) {
            starStories = decoded
        }
        if let data = defaults.data(forKey: StorageKey.achievements.rawValue), let decoded = try? decoder.decode([Achievement].self, from: data) {
            achievements = decoded
        }
        if let data = defaults.data(forKey: StorageKey.interviewNotes.rawValue), let decoded = try? decoder.decode([InterviewNote].self, from: data) {
            interviewNotes = decoded
        }
    }
}

// MARK: - Seed Content
extension DataStore {
    static let seedRolePacks: [RolePack] = [
        RolePack(name: "Retail & Customer Service", description: "Handling customers, sales, and service excellence.", isProOnly: false),
        RolePack(name: "Office/Admin", description: "Organisation, scheduling, and communication strengths.", isProOnly: true),
        RolePack(name: "Warehouse/Operations", description: "Safety, efficiency, and teamwork in operations.", isProOnly: true),
        RolePack(name: "Graduate/First Job", description: "Potential, learning agility, and internships.", isProOnly: false),
        RolePack(name: "Tech/QA", description: "Quality mindset, testing strategy, and problem solving.", isProOnly: true),
        RolePack(name: "Healthcare/Care", description: "Compassion, diligence, and patient outcomes.", isProOnly: true)
    ]

    static var dailyRotation: [InterviewQuestion] {
        seedQuestions.filter { $0.rolePack == nil }
    }

    static var seedQuestions: [InterviewQuestion] {
        let retail = seedRolePacks[0]
        let graduate = seedRolePacks[3]
        let tech = seedRolePacks[4]

        return [
            InterviewQuestion(
                category: .aboutYou,
                text: "Tell me about yourself",
                whyItMatters: "Shows how you frame your story and what you value.",
                answerStructure: ["Present role or studies", "Key strengths and themes", "Relevant achievements", "Why this opportunity"],
                exampleAnswers: [
                    "I'm a customer-focused assistant with three years in retail, known for calm problem-solving and keeping queues moving.",
                    "As a QA analyst, I pair curiosity with structure—recently I reduced escape bugs by 30% through risk-based testing."
                ]
            ),
            InterviewQuestion(
                category: .behavioural,
                text: "Describe a time you overcame a setback",
                whyItMatters: "Resilience and ownership are crucial in any role.",
                answerStructure: ["Situation context", "Your role", "Action taken", "Result and learning"],
                exampleAnswers: [
                    "During a peak sale our POS crashed; I organised manual receipts and kept customers informed, avoiding lost sales.",
                    "While testing a release, I found flaky tests blocking CI. I isolated them, marked unstable, and added monitoring to unblock the team."
                ]
            ),
            InterviewQuestion(
                category: .strengthsWeaknesses,
                text: "What is a strength you're known for?",
                whyItMatters: "Tests self-awareness and impact on others.",
                answerStructure: ["Name the strength", "Example where it mattered", "Impact", "How it helps this role"],
                exampleAnswers: [
                    "I bring calm structure. At my last store I introduced a closing checklist that cut errors by half.",
                    "I translate between product and QA. Pairing with PMs reduced misunderstood tickets and sped up delivery."
                ]
            ),
            InterviewQuestion(
                category: .behavioural,
                text: "Tell me about a time you helped a teammate grow",
                whyItMatters: "Highlights coaching and collaboration.",
                answerStructure: ["Person's goal", "Support you offered", "Actions taken", "Outcome"],
                exampleAnswers: [
                    "A new colleague struggled with returns; I made a quick guide and shadowed her for two shifts—her confidence jumped.",
                    "I mentored a junior QA on exploratory techniques; their sessions uncovered critical edge cases before launch."
                ],
                rolePack: graduate
            ),
            InterviewQuestion(
                category: .pressure,
                text: "How do you handle pressure or busy periods?",
                whyItMatters: "Assesses prioritisation and composure.",
                answerStructure: ["Frame pressure positively", "Describe system you use", "Example", "Result"],
                exampleAnswers: [
                    "I triage quickly—during holiday rush I split tasks with the team, kept communication clear, and met targets.",
                    "In a Sev1 incident I created a quick test matrix, aligned with devs, and validated the hotfix within the hour."
                ],
                rolePack: retail
            ),
            InterviewQuestion(
                category: .leadership,
                text: "Describe a decision you made with incomplete data",
                whyItMatters: "Shows judgement and communication.",
                answerStructure: ["Context and risk", "Options considered", "Decision and why", "Result and review"],
                exampleAnswers: [
                    "With a delivery delay and no ETA, I chose to reorder staples to avoid stockouts, informing the manager early.",
                    "Lacking performance metrics, I piloted a smoke-test suite to gather data before full automation investment."
                ],
                rolePack: tech
            )
        ]
    }
}
