import SwiftUI
import SwiftData

struct AddJobView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var companyName = ""
    @State private var roleTitle = ""

    @State private var selectedStage: JobStage = .saved

    @State private var selectedLocationType: LocationType = .remote
    @State private var locationDetail = ""

    @State private var salaryMin = ""
    @State private var salaryMax = ""

    @State private var includeNextInterview = false
    @State private var nextInterviewDate = Date()
    @State private var nextInterviewNotes = ""

    @State private var generalNotes = ""

    private var canSave: Bool {
        !companyName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !roleTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    SectionHeader(title: "Company", actionTitle: "") { }

                    formField(title: "Company Name", icon: "building.2") {
                        TextField("e.g. Google", text: $companyName)
                            .textInputAutocapitalization(.words)
                    }

                    SectionHeader(title: "Role", actionTitle: "") { }

                    formField(title: "Job Title", icon: "briefcase") {
                        TextField("e.g. Product Designer", text: $roleTitle)
                            .textInputAutocapitalization(.words)
                    }

                    SectionHeader(title: "Location", actionTitle: "") { }

                    locationChips

                    formField(title: "City or Town (optional)", icon: "mappin.and.ellipse") {
                        TextField("e.g. Manchester", text: $locationDetail)
                            .textInputAutocapitalization(.words)
                    }

                    SectionHeader(title: "Salary Range (annual, optional)", actionTitle: "") { }

                    salaryFields

                    SectionHeader(title: "Application Stage", actionTitle: "") { }

                    stagePicker

                    SectionHeader(title: "Next Interview", actionTitle: "") { }

                    nextInterviewBlock

                    SectionHeader(title: "Notes", actionTitle: "") { }

                    notesField
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 140)
            }
            .background(Color.cream50)
            .navigationTitle("Add Application")
            .navigationBarTitleDisplayMode(.inline)
            .tapToDismissKeyboard()
            .safeAreaInset(edge: .bottom) {
                actionBar
            }
            .ignoresSafeArea(.keyboard, edges: .bottom)
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
    }

    // MARK: - UI

    private var locationChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(LocationType.allCases, id: \.self) { item in
                    Chip(title: item.title, isSelected: selectedLocationType == item) {
                        selectedLocationType = item
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
                    Text("£")
                        .foregroundStyle(Color.ink500)

                    TextField("Min", text: $salaryMin)
                        .keyboardType(.numberPad)
                }
            }

            CardContainer(backgroundColor: Color.surfaceWhite, cornerRadius: 16, showShadow: false) {
                HStack(spacing: 8) {
                    Text("£")
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
                Toggle("Interview scheduled?", isOn: $includeNextInterview)
                    .tint(Color.sage500)

                if includeNextInterview {
                    HStack(spacing: 12) {
                        DatePicker("Date", selection: $nextInterviewDate, displayedComponents: .date)
                            .datePickerStyle(.compact)

                        DatePicker("Time", selection: $nextInterviewDate, displayedComponents: .hourAndMinute)
                            .datePickerStyle(.compact)
                    }
                    .font(.subheadline)
                    .foregroundStyle(Color.ink600)

                    TextField("Who are you meeting? Any topics to prepare for?", text: $nextInterviewNotes, axis: .vertical)
                        .font(.subheadline)
                        .foregroundStyle(Color.ink900)
                        .lineLimit(3, reservesSpace: true)
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

    private func formField<Content: View>(title: String, icon: String, @ViewBuilder
    content: @escaping () -> Content) -> some View {
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

    private var actionBar: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                Button("Cancel") {
                    dismiss()
                }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.ink600)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.surfaceWhite)
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color.ink200, lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .buttonStyle(.plain)

                Button("Save") {
                    saveJob()
                }
                .font(.headline.weight(.semibold))
                .foregroundStyle(Color.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.sage500.opacity(canSave ? 1 : 0.5))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .buttonStyle(.plain)
                .disabled(!canSave)
            }
            .padding(.horizontal, 20)
        }
        .padding(.top, 8)
        .padding(.bottom, 12)
        .background(Color.cream50)
        .overlay(
            Divider()
                .opacity(0.4),
            alignment: .top
        )
    }

    // MARK: - Save

    private func saveJob() {
        let trimmedCompany = companyName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedRole = roleTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedCompany.isEmpty, !trimmedRole.isEmpty else { return }

        let city = locationDetail.trimmingCharacters(in: .whitespacesAndNewlines)
        let locationValue: String? = {
            if city.isEmpty { return selectedLocationType.title }
            return "\(selectedLocationType.title) · \(city)"
        }()

        let min = salaryMin.trimmingCharacters(in: .whitespacesAndNewlines)
        let max = salaryMax.trimmingCharacters(in: .whitespacesAndNewlines)
        let salaryValue: String? = {
            if min.isEmpty && max.isEmpty { return nil }
            if !min.isEmpty && max.isEmpty { return "£\(min)+"
            }
            if min.isEmpty && !max.isEmpty { return "Up to £\(max)" }
            return "£\(min)–£\(max)"
        }()

        let job = Job(companyName: trimmedCompany, roleTitle: trimmedRole, stage: selectedStage)
        job.location = locationValue
        job.salary = salaryValue
        job.generalNotes = generalNotes.trimmingCharacters(in: .whitespacesAndNewlines)

        if includeNextInterview {
            job.nextInterviewDate = nextInterviewDate

            let trimmedNextNotes = nextInterviewNotes.trimmingCharacters(in: .whitespacesAndNewlines)
            job.nextInterviewNotes = trimmedNextNotes.isEmpty ? nil : trimmedNextNotes
        }

        modelContext.insert(job)
        AnalyticsEventLogger.shared.log(.jobSaved)
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        dismiss()
    }
}

private enum LocationType: CaseIterable {
    case remote, hybrid, onsite

    var title: String {
        switch self {
        case .remote: return "Remote"
        case .hybrid: return "Hybrid"
        case .onsite: return "On-site"
        }
    }
}
