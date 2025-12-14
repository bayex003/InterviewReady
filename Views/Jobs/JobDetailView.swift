import SwiftUI

struct JobDetailView: View {
    @Bindable var job: Job
    
    var body: some View {
        Form {
            // 1. Header Section
            Section {
                HStack {
                    VStack(alignment: .leading) {
                        Text(job.companyName)
                            .font(.title)
                            .fontWeight(.bold)
                        Text(job.roleTitle)
                            .font(.headline)
                            .foregroundStyle(.gray)
                    }
                    Spacer()
                    // Stage Picker
                    Picker("Stage", selection: $job.stage) {
                        ForEach(JobStage.allCases, id: \.self) { stage in
                            Text(stage.rawValue).tag(stage)
                        }
                    }
                    .labelsHidden()
                    .pickerStyle(.menu)
                    .tint(Color.sage500)
                }
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())
            }
            
            // 2. Logistics
            Section("Logistics") {
                DatePicker("Date Applied", selection: $job.dateApplied, displayedComponents: .date)
                
                // Optional Interview Date
                Toggle("Interview Scheduled?", isOn: Binding(
                    get: { job.nextInterviewDate != nil },
                    set: { hasDate in
                        if hasDate { job.nextInterviewDate = Date() }
                        else { job.nextInterviewDate = nil }
                    }
                ))
                .tint(Color.sage500)
                
                if let _ = job.nextInterviewDate {
                    DatePicker("Interview Date", selection: Binding(
                        get: { job.nextInterviewDate ?? Date() },
                        set: { job.nextInterviewDate = $0 }
                    ))
                    .foregroundStyle(Color.sage500)
                }
            }
            
            // 3. Notes (With Dictation!)
            Section("Notes & Research") {
                ZStack(alignment: .bottomTrailing) {
                    TextEditor(text: $job.generalNotes)
                        .frame(minHeight: 150)
                }
            }
        }
        .navigationTitle("Job Details")
        .navigationBarTitleDisplayMode(.inline)
    }
}
