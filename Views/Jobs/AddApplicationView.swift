import SwiftUI

struct AddApplicationView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var jobsStore: JobsStore

    @State private var companyName = ""
    @State private var jobTitle = ""
    @State private var locationDetail = ""
    @State private var selectedLocationType: JobLocationType = .remote
    @State private var selectedStage: JobStage = .applied
    @State private var salaryMin = ""
    @State private var salaryMax = ""
    @State private var nextInterviewDate = Date()
    @State private var nextInterviewNotes = ""
    @State private var generalNotes = ""
    @State private var includeNextInterview = false

    private var canSave: Bool {
        !companyName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !jobTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                SectionHeader(title: "Company")

                formField(title: "Company Name", icon: "building.2") {
                    TextField("e.g. Google", text: $companyName)
                        .textInputAutocapitalization(.words)
                }

                SectionHeader(title: "Role")

                formField(title: "Job Title", icon: "briefcase") {
                    TextField("e.g. Product Designer", text: $jobTitle)
                        .textInputAutocapitalization(.words)
                }

                SectionHeader(title: "Location")

                locationChips

                formField(title: "City, State or Country", icon: "mappin.and.ellipse") {
                    TextField("City, State or Country", text: $locationDetail)
                        .textInputAutocapitalization(.words)
                }

                SectionHeader(title: "Salary Range (Annual)")

                salaryFields

                SectionHeader(title: "Application Stage")

                stagePicker

                SectionHeader(title: "Next Interview")

                nextInterviewBlock

                SectionHeader(title: "Notes")

                notesField
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 120)
        }
        .background(Color.cream50)
        .navigationTitle("Add Application")
        .navigationBarTitleDisplayMode(.inline)
        .tapToDismissKeyboard()
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .foregroundStyle(Color.ink600)
                        .frame(width: 44, height: 44)
                }
                .accessibilityLabel("Close")
            }

            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    saveJob()
                }
                .disabled(!canSave)
            }
        }
    }

    private var locationChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(JobLocationType.allCases) { location in
                    Chip(
                        title: location.rawValue,
                        isSelected: selectedLocationType == location
                    ) {
                        selectedLocationType = location
                    }
                }
            }
            .padding(.vertical, 4)
        }
    }

    private var salaryFields: some View {
        HStack(spacing: 12) {
            CardContainer(backgroundColor: Color.surfaceWhite, cornerRadius: 16, showShadow: false) {
                HStack(spacing: 8) {
                    Text("$")
                        .foregroundStyle(Color.ink500)

                    TextField("Min", text: $salaryMin)
                        .keyboardType(.numberPad)
                }
            }

            CardContainer(backgroundColor: Color.surfaceWhite, cornerRadius: 16, showShadow: false) {
                HStack(spacing: 8) {
                    Text("$")
                        .foregroundStyle(Color.ink500)

                    TextField("Max", text: $salaryMax)
                        .keyboardType(.numberPad)
                }
            }
        }
    }

    private var stagePicker: some View {
        CardContainer(backgroundColor: Color.surfaceWhite, cornerRadius: 16, showShadow: false) {
            Picker("Stage", selection: $selectedStage) {
                ForEach(JobStage.allCases, id: \.self) { stage in
                    Text(stage.rawValue).tag(stage)
                }
            }
            .pickerStyle(.menu)
        }
    }

    private var nextInterviewBlock: some View {
        CardContainer(backgroundColor: Color.surfaceWhite, cornerRadius: 18, showShadow: false) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 10) {
                    Circle()
                        .fill(Color.sage100)
                        .frame(width: 36, height: 36)
                        .overlay(
                            Image(systemName: "calendar")
                                .foregroundStyle(Color.sage500)
                        )

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Next Interview")
                            .font(.headline)
                            .foregroundStyle(Color.ink900)

                        Text("Schedule details & notes")
                            .font(.caption)
                            .foregroundStyle(Color.ink500)
                    }
                }

                HStack(spacing: 12) {
                    DatePicker("Date", selection: $nextInterviewDate, displayedComponents: .date)
                        .datePickerStyle(.compact)
                        .onChange(of: nextInterviewDate) { _, _ in
                            includeNextInterview = true
                        }

                    DatePicker("Time", selection: $nextInterviewDate, displayedComponents: .hourAndMinute)
                        .datePickerStyle(.compact)
                        .onChange(of: nextInterviewDate) { _, _ in
                            includeNextInterview = true
                        }
                }
                .font(.subheadline)
                .foregroundStyle(Color.ink600)

                TextField("Who are you meeting? Any specific topics to prepare for?", text: $nextInterviewNotes, axis: .vertical)
                    .font(.subheadline)
                    .foregroundStyle(Color.ink900)
                    .lineLimit(3, reservesSpace: true)
                    .onChange(of: nextInterviewNotes) { _, newValue in
                        if !newValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            includeNextInterview = true
                        }
                    }
            }
        }
    }

    private var notesField: some View {
        CardContainer(backgroundColor: Color.surfaceWhite, cornerRadius: 18, showShadow: false) {
            TextField("Add any extra notes...", text: $generalNotes, axis: .vertical)
                .font(.subheadline)
                .foregroundStyle(Color.ink900)
                .lineLimit(5, reservesSpace: true)
        }
    }

    private func formField<Content: View>(title: String, icon: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .foregroundStyle(Color.ink900)

            CardContainer(backgroundColor: Color.surfaceWhite, cornerRadius: 16, showShadow: false) {
                HStack(spacing: 10) {
                    Image(systemName: icon)
                        .foregroundStyle(Color.ink500)

                    content()
                        .font(.subheadline)
                        .foregroundStyle(Color.ink900)
                }
            }
        }
    }

    private func saveJob() {
        let trimmedCompany = companyName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedRole = jobTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedCompany.isEmpty, !trimmedRole.isEmpty else { return }

        let trimmedLocation = locationDetail.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedMin = salaryMin.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedMax = salaryMax.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedNextNotes = nextInterviewNotes.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedNotes = generalNotes.trimmingCharacters(in: .whitespacesAndNewlines)

        let nextDate: Date? = includeNextInterview || !trimmedNextNotes.isEmpty ? nextInterviewDate : nil

        let newJob = JobApplication(
            companyName: trimmedCompany,
            roleTitle: trimmedRole,
            stage: selectedStage,
            locationType: selectedLocationType,
            locationDetail: trimmedLocation.isEmpty ? nil : trimmedLocation,
            salaryMin: trimmedMin.isEmpty ? nil : trimmedMin,
            salaryMax: trimmedMax.isEmpty ? nil : trimmedMax,
            nextInterviewDate: nextDate,
            nextInterviewNotes: trimmedNextNotes,
            notes: trimmedNotes
        )

        jobsStore.add(newJob)
        dismiss()
    }
}
