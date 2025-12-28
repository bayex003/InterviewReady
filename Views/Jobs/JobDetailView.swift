import SwiftUI

struct JobDetailFormView: View {
    @Bindable var job: Job

    var body: some View {
        Form {
            // 1) Header
            Section {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(job.companyName)
                            .font(.title)
                            .fontWeight(.bold)

                        Text(job.roleTitle)
                            .font(.headline)
                            .foregroundStyle(.gray)
                    }

                    Spacer()

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

            // 2) Role Details
            Section("Role Details") {
                TextField("Salary (e.g. £55k–£65k, £30/hr)", text: Binding(
                    get: { job.salary ?? "" },
                    set: { newValue in
                        let trimmed = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
                        job.salary = trimmed.isEmpty ? nil : trimmed
                    }
                ))
                .keyboardType(.numbersAndPunctuation)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()

                TextField("Location (e.g. Manchester · Hybrid)", text: Binding(
                    get: { job.location ?? "" },
                    set: { newValue in
                        let trimmed = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
                        job.location = trimmed.isEmpty ? nil : trimmed
                    }
                ))
                .textInputAutocapitalization(.words)
                .autocorrectionDisabled()
            }

            // 3) Logistics
            Section("Logistics") {
                DatePicker("Date Applied", selection: $job.dateApplied, displayedComponents: .date)

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

            // 4) Notes
            Section("Notes & Research") {
                TextEditor(text: $job.generalNotes)
                    .frame(minHeight: 150)
            }
        }
        .navigationTitle("Job Details")
        .navigationBarTitleDisplayMode(.inline)
        .scrollDismissesKeyboard(.interactively)
    }
}

