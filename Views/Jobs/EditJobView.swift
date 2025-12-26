import SwiftUI
import SwiftData

struct EditJobView: View {
    @Bindable var job: Job
    @Environment(\.dismiss) private var dismiss

    @State private var showConfetti = false

    var body: some View {
        ZStack {
            Form {
                Section("Details") {
                    TextField("Company", text: $job.companyName)
                    TextField("Role", text: $job.roleTitle)

                    Picker("Stage", selection: $job.stage) {
                        ForEach(JobStage.allCases, id: \.self) { stage in
                            Text(stage.rawValue).tag(stage)
                        }
                    }
                    // IMPORTANT: Don't add tap gestures over this screen (it breaks pickers/textfields)

                    .onChange(of: job.stage) { _, newValue in
                        if newValue == .offer {
                            triggerCelebration()
                        }
                    }
                }

                // Role details (salary/location)
                Section("Role Details") {
                    TextField("Salary (e.g. £55k–£65k, £30/hr)", text: Binding(
                        get: { job.salary ?? "" },
                        set: { job.salary = $0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : $0 }
                    ))

                    TextField("Location (e.g. Manchester · Hybrid)", text: Binding(
                        get: { job.location ?? "" },
                        set: { job.location = $0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : $0 }
                    ))
                }

                Section("Notes") {
                    TextEditor(text: $job.generalNotes)
                        .frame(minHeight: 120)
                }

                Section("Dates") {
                    DatePicker("Date Applied", selection: $job.dateApplied, displayedComponents: .date)

                    Toggle("Interview Scheduled?", isOn: Binding(
                        get: { job.nextInterviewDate != nil },
                        set: { hasDate in
                            if hasDate {
                                job.nextInterviewDate = Date()
                            } else {
                                job.nextInterviewDate = nil
                            }
                        }
                    ))
                    .tint(Color.sage500)

                    if let _ = job.nextInterviewDate {
                        DatePicker("Next Interview", selection: Binding(
                            get: { job.nextInterviewDate ?? Date() },
                            set: { job.nextInterviewDate = $0 }
                        ))

                        Button("Remove Interview Date", role: .destructive) {
                            job.nextInterviewDate = nil
                        }
                    }
                }
            }

            if showConfetti {
                ConfettiView()
                    .allowsHitTesting(false)
                    .ignoresSafeArea()
            }
        }
        .navigationTitle("Edit Job")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Done") { dismiss() }
            }
        }

        // ✅ KEY: hide the floating tab bar on this pushed screen
        .hidesFloatingTabBar()

        // ✅ Optional: only dismiss keyboard when tapping outside inputs (doesn't break pickers)
        .scrollDismissesKeyboard(.interactively)
        .floatingTabBarHidden(true)
        .formKeyboardBehavior()

    }

    private func triggerCelebration() {
        withAnimation {
            showConfetti = true
        }
        UINotificationFeedbackGenerator().notificationOccurred(.success)

        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            withAnimation {
                showConfetti = false
            }
        }
    }
}

