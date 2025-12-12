import SwiftUI
import SwiftData

@main
struct InterviewReadyApp: App {
    // 1. Set up the SwiftData container for your models
    let container: ModelContainer
    
    init() {
        do {
            // Add Question.self and Story.self here once created
            let schema = Schema([Job.self])
            let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
            container = try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            // This will be your RootContentView later, containing the TabBar
            Text("Temporary Root View - Build Tabs Here")
                .appBackground() // Applies your cream background
                .onAppear {
                    // 2. Run the seeder on launch
                    DataSeeder.shared.seedDataIfNeeded(modelContext: container.mainContext)
                }
        }
        // 3. Inject the container into the environment
        .modelContainer(container)
    }
}
