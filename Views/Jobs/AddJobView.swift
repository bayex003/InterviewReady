import SwiftUI
import SwiftData

struct AddJobView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    // Form State
    @State private var companyName = ""
    @State private var roleTitle = ""
    @State private var selectedStage: JobStage = .applied
    @State private var applicationDate = Date()
    @State private var nextInterviewDate: Date = Date()
    @State private var hasScheduledInterview = false
    @State private var generalNotes = ""

    // ✅ V2 (free): Optional fields
    @State private var salary = ""
    @State private var location = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Job Details") {
                    TextField("Company Name (e.g. Spotify)", text: $companyName)
                        .textInputAutocapitalization(.words)

                    TextField("Role Title (e.g. iOS Engineer)", text: $roleTitle)
                        .textInputAutocapitalization(.words)

                    // ✅ New fields (optional)
                    TextField("Salary (optional) (e.g. £55k–£65k, £30/hr)", text: $salary)
                        .keyboardType(.numbersAndPunctuation)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()

                    TextField("Location (optional) (e.g. Manchester · Hybrid)", text: $location)
                        .textInputAutocapitalization(.words)
                        .autocorrectionDisabled()

                    Picker("Current Stage", selection: $selectedStage) {
                        ForEach(JobStage.allCases, id: \.self) { stage in
                            Text(stage.rawValue).tag(stage)
                        }
                    }
                }

                Section("Timeline") {
                    DatePicker("Date Applied", selection: $applicationDate, displayedComponents: .date)

                    Toggle("Interview Scheduled?", isOn: $hasScheduledInterview)
                        .tint(Color.sage500)

                    if hasScheduledInterview {
                        DatePicker("Interview Date", selection: $nextInterviewDate)
                            .foregroundStyle(Color.sage500)
                    }
                }

                Section {
                    TextEditor(text: $generalNotes)
                        .frame(minHeight: 120)
                        .scrollContentBackground(.hidden)
                } header: {
                    Text("Notes")
                }
            }
            .navigationTitle("Add Job")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveJob() }
                        .disabled(companyName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                                  roleTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .formKeyboardBehavior()
            .floatingTabBarHidden(true)

        }
    }

    private func saveJob() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)

        let trimmedCompany = companyName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedRole = roleTitle.trimmingCharacters(in: .whitespacesAndNewlines)

        let newJob = Job(companyName: trimmedCompany, roleTitle: trimmedRole, stage: selectedStage)
        newJob.dateApplied = applicationDate
        newJob.generalNotes = generalNotes

        let trimmedSalary = salary.trimmingCharacters(in: .whitespacesAndNewlines)
        newJob.salary = trimmedSalary.isEmpty ? nil : trimmedSalary

        let trimmedLocation = location.trimmingCharacters(in: .whitespacesAndNewlines)
        newJob.location = trimmedLocation.isEmpty ? nil : trimmedLocation

        if hasScheduledInterview {
            newJob.nextInterviewDate = nextInterviewDate
        }

        modelContext.insert(newJob)
        dismiss()
    }
}

