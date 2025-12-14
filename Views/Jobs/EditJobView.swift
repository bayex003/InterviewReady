import SwiftUI
import SwiftData

struct EditJobView: View {
    @Bindable var job: Job
    @Environment(\.dismiss) private var dismiss
    
    // NEW: State to trigger confetti
    @State private var showConfetti = false
    
    var body: some View {
        ZStack {
            Form {
                Section("Details") {
                    TextField("Company", text: $job.companyName)
                    TextField("Role", text: $job.roleTitle)
                    
                    // NEW: Watch for changes on the Picker
                    Picker("Stage", selection: $job.stage) {
                        ForEach(JobStage.allCases, id: \.self) { stage in
                            Text(stage.rawValue).tag(stage)
                        }
                    }
                    .onChange(of: job.stage) { oldValue, newValue in
                        if newValue == .offer {
                            triggerCelebration()
                        }
                    }
                }
                
                Section("Notes") {
                    TextEditor(text: $job.generalNotes)
                        .frame(minHeight: 100)
                }
                
                Section("Dates") {
                    DatePicker("Date Applied", selection: $job.dateApplied, displayedComponents: .date)
                    
                    if let _ = job.nextInterviewDate {
                        DatePicker("Next Interview", selection: Binding(
                            get: { job.nextInterviewDate ?? Date() },
                            set: { job.nextInterviewDate = $0 }
                        ))
                        
                        Button("Remove Interview Date") {
                            job.nextInterviewDate = nil
                        }
                        .foregroundStyle(.red)
                    } else {
                        Button("Add Interview Date") {
                            job.nextInterviewDate = Date()
                        }
                    }
                }
            }
            
            // NEW: Overlay Confetti
            if showConfetti {
                ConfettiView()
                    .allowsHitTesting(false) // Let user click through confetti
                    .ignoresSafeArea()
            }
        }
        .navigationTitle("Edit Job")
        .toolbar {
            Button("Done") { dismiss() }
        }
    }
    
    // Helper function for the effect
    private func triggerCelebration() {
        // 1. Visual
        withAnimation {
            showConfetti = true
        }
        
        // 2. Haptic
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        
        // 3. Stop after 3 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            withAnimation {
                showConfetti = false
            }
        }
    }
}
