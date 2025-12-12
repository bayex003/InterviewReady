import Foundation
import SwiftData
import SwiftUI

struct InitialQuestionData: Decodable {
    let text: String
    let category: String
}
// Add similar struct for InitialStoryData

class DataSeeder {
    static let shared = DataSeeder()
    private let hasSeededKey = "hasSeededInitialData_v1"
    
    private init() {}
    
    @MainActor
    func seedDataIfNeeded(modelContext: ModelContext) {
        // Check user defaults flag
        guard !UserDefaults.standard.bool(forKey: hasSeededKey) else { return }
        
        print("Attempting to seed initial data...")
        
        seedQuestions(context: modelContext)
        // seedStories(context: modelContext)
        
        do {
            try modelContext.save()
            // Set flag so it doesn't run again
            UserDefaults.standard.set(true, forKey: hasSeededKey)
            print("Data seeding complete.")
        } catch {
            print("Failed to save seeded data: \(error)")
        }
    }
    
    @MainActor
    private func seedQuestions(context: ModelContext) {
        guard let url = Bundle.main.url(forResource: "initial_questions", withExtension: "json") else {
             print("Could not find initial_questions.json")
             return
        }
        
        do {
            let data = try Data(contentsOf: url)
            let questionsData = try JSONDecoder().decode([InitialQuestionData].self, from: data)
            
            for qData in questionsData {
                // Provided you have created the Question model:
                // let newQuestion = Question(text: qData.text, category: qData.category)
                // context.insert(newQuestion)
                print("Would insert: \(qData.text)")
            }
        } catch {
            print("Failed to decode questions JSON: \(error)")
        }
    }
}
