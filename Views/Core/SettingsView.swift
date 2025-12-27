import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var purchaseManager: PurchaseManager
    @EnvironmentObject private var dataController: AppDataController
    @EnvironmentObject private var jobsStore: JobsStore

    // Preferences
    @AppStorage("isHapticFeedbackEnabled") private var isHapticFeedbackEnabled = true
    @AppStorage("isSystemThemeMatchEnabled") private var isSystemThemeMatchEnabled = true

    // Notification State
    @AppStorage("isDailyReminderEnabled") private var isDailyReminderEnabled = false
    @AppStorage("dailyReminderTime") private var dailyReminderTime: Double = 32400 // 9:00 AM

    // Feedback configuration
    private let supportEmail = "support@example.com"
    private let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"

    // Alerts
    @State private var showResetConfirmation = false
    @State private var showResetSuccess = false

    // Paywall
    @State private var showPaywall = false

    // Export
    @State private var showExportOptions = false
    @State private var showShareSheet = false
    @State private var shareItems: [Any] = []
    @State private var isGeneratingExport = false
    @State private var showExportErrorAlert = false
    @State private var showExportSelectionAlert = false
    @State private var exportSelection = ExportSelection()
    @State private var exportFormat: ExportFormat = .csv

    // MARK: - Bindings

    private var reminderTimeBinding: Binding<Date> {
        Binding(
            get: { Date(timeIntervalSince1970: dailyReminderTime) },
            set: { newDate in
                dailyReminderTime = newDate.timeIntervalSince1970
                scheduleNotification()
            }
        )
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack {
                Color.cream50.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        headerSection
                        proSection
                        preferencesSection
                        remindersSection
                        dataManagementSection
                        supportSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 120)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView()
                    .environmentObject(purchaseManager)
            }
            .sheet(isPresented: $showExportOptions) {
                ExportOptionsSheet(
                    selection: $exportSelection,
                    format: $exportFormat,
                    isGenerating: isGeneratingExport,
                    onExport: exportSelectedData
                )
            }
            .sheet(isPresented: $showShareSheet, onDismiss: {
                shareItems = []
            }) {
                ShareSheet(items: shareItems)
            }
            .alert("Clear all data?", isPresented: $showResetConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Delete Everything", role: .destructive) {
                    resetApp()
                }
            } message: {
                Text("This will permanently delete your jobs, stories, questions, and practice attempts. This action cannot be undone.")
            }
            .alert("Data Cleared", isPresented: $showResetSuccess) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Your app has been reset to a clean state.")
            }
            .alert("Select at least one item", isPresented: $showExportSelectionAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Choose at least one data type to export.")
            }
            .alert("Export failed", isPresented: $showExportErrorAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("We couldn’t generate the export files. Please try again.")
            }
        }
    }

    // MARK: - Sections

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Settings")
                .font(.largeTitle.bold())
                .foregroundStyle(Color.ink900)

            Text("Manage your experience, reminders, and data.")
                .font(.subheadline)
                .foregroundStyle(Color.ink600)
        }
    }

    private var proSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Pro")

            CardContainer(backgroundColor: Color.surfaceWhite, cornerRadius: 22, showShadow: false) {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        HStack(spacing: 8) {
                            Image(systemName: "sparkles")
                                .foregroundStyle(Color.sage500)
                            Text(purchaseManager.isPro ? "InterviewReady Pro" : "Unlock Pro Features")
                                .font(.headline)
                                .foregroundStyle(Color.ink900)
                        }

                        Spacer()

                        Chip(title: purchaseManager.isPro ? "Active" : "Pro", isSelected: true)
                    }

                    Text("Get unlimited practice questions, AI feedback, and export your career stories.")
                        .font(.subheadline)
                        .foregroundStyle(Color.ink600)

                    PrimaryCTAButton(title: purchaseManager.isPro ? "Manage Subscription" : "Upgrade to Pro", systemImage: "chevron.right") {
                        if purchaseManager.isPro {
                            refreshProStatus()
                        } else {
                            showPaywall = true
                        }
                    }
                }
            }
        }
    }

    private var preferencesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "App Preferences")

            CardContainer(backgroundColor: Color.surfaceWhite, cornerRadius: 22, showShadow: false) {
                VStack(spacing: 12) {
                    SettingsRow(icon: "wave.3.right", title: "Haptic Feedback") {
                        Toggle("Haptic Feedback", isOn: $isHapticFeedbackEnabled)
                            .labelsHidden()
                            .tint(Color.sage500)
                    }

                    Divider().opacity(0.6)

                    SettingsRow(icon: "circle.lefthalf.filled", title: "System Theme Match") {
                        Toggle("System Theme Match", isOn: $isSystemThemeMatchEnabled)
                            .labelsHidden()
                            .tint(Color.sage500)
                    }
                }
            }
        }
    }

    private var remindersSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Reminders")

            CardContainer(backgroundColor: Color.surfaceWhite, cornerRadius: 22, showShadow: false) {
                VStack(spacing: 12) {
                    SettingsRow(icon: "bell", title: "Daily Practice") {
                        Toggle("Daily Practice", isOn: $isDailyReminderEnabled)
                            .labelsHidden()
                            .tint(Color.sage500)
                            .onChange(of: isDailyReminderEnabled) { _, newValue in
                                if newValue {
                                    NotificationManager.shared.requestPermission { granted in
                                        if !granted { isDailyReminderEnabled = false }
                                    }
                                }
                                scheduleNotification()
                            }
                    }

                    if isDailyReminderEnabled {
                        Divider().opacity(0.6)

                        SettingsRow(icon: "clock", title: "Reminder Time") {
                            DatePicker("Time", selection: reminderTimeBinding, displayedComponents: .hourAndMinute)
                                .labelsHidden()
                        }
                    }
                }
            }
        }
    }

    private var dataManagementSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Data Management")

            CardContainer(backgroundColor: Color.surfaceWhite, cornerRadius: 22, showShadow: false) {
                VStack(spacing: 12) {
                    Button {
                        showExportOptions = true
                    } label: {
                        SettingsRow(icon: "square.and.arrow.up", title: "Export My Data") {
                            Image(systemName: "chevron.right")
                                .foregroundStyle(Color.ink400)
                        }
                    }
                    .buttonStyle(.plain)

                    Divider().opacity(0.6)

                    Button(role: .destructive) {
                        showResetConfirmation = true
                    } label: {
                        SettingsRow(icon: "trash", title: "Clear All Data", titleColor: .red) {
                            Image(systemName: "chevron.right")
                                .foregroundStyle(Color.ink400)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }

            Text("Your data is stored locally on this device. Exporting creates CSV or raw text files for sharing.")
                .font(.footnote)
                .foregroundStyle(Color.ink500)
        }
    }

    private var supportSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Support & About")

            CardContainer(backgroundColor: Color.surfaceWhite, cornerRadius: 22, showShadow: false) {
                VStack(spacing: 12) {
                    if let url = supportMailURL {
                        Link(destination: url) {
                            SettingsRow(icon: "envelope", title: "Send Feedback") {
                                Image(systemName: "chevron.right")
                                    .foregroundStyle(Color.ink400)
                            }
                        }
                        .buttonStyle(.plain)
                    }

                    Divider().opacity(0.6)

                    SettingsRow(icon: "info.circle", title: "App Version") {
                        Text(appVersion)
                            .font(.subheadline)
                            .foregroundStyle(Color.ink500)
                    }

                    Divider().opacity(0.6)

                    SettingsRow(icon: "icloud", title: "iCloud Sync") {
                        Text(purchaseManager.isPro && dataController.isUsingCloud ? "On" : "Off")
                            .font(.subheadline)
                            .foregroundStyle(Color.ink500)
                    }
                }
            }
        }
    }

    private var supportMailURL: URL? {
        let mailto = "mailto:\(supportEmail)?subject=InterviewReady%20Feedback%20(v\(appVersion))"
        return URL(string: mailto)
    }

    // MARK: - Helpers

    private func scheduleNotification() {
        let date = Date(timeIntervalSince1970: dailyReminderTime)
        NotificationManager.shared.scheduleDailyReminder(isEnabled: isDailyReminderEnabled, time: date)
    }

    private func resetApp() {
        do {
            try modelContext.delete(model: Job.self)
            try modelContext.delete(model: Story.self)
            try modelContext.delete(model: Question.self)
            try modelContext.delete(model: PracticeAttempt.self)
            try modelContext.save()
            jobsStore.removeAll()
            showResetSuccess = true
        } catch {
            print("Failed to reset: \(error)")
        }
    }

    @MainActor
    private func exportSelectedData() {
        guard !isGeneratingExport else { return }
        guard exportSelection.hasSelection else {
            showExportSelectionAlert = true
            return
        }

        isGeneratingExport = true

        if let exportURLs = DataExportManager.generateExportFiles(
            context: modelContext,
            jobs: jobsStore.jobs,
            includeStories: exportSelection.includeStories,
            includeAttempts: exportSelection.includeAttempts,
            includeJobs: exportSelection.includeJobs,
            includeQuestions: exportSelection.includeQuestions,
            format: exportFormat
        ) {
            shareItems = exportURLs
            showExportOptions = false
            DispatchQueue.main.async {
                showShareSheet = true
            }
        } else {
            showExportErrorAlert = true
        }

        isGeneratingExport = false
    }

    private func refreshProStatus() {
        Task {
            await purchaseManager.refreshEntitlements()
        }
    }
}

private struct SettingsRow<Accessory: View>: View {
    let icon: String
    let title: String
    var titleColor: Color = .ink900
    @ViewBuilder let accessory: () -> Accessory

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.sage100.opacity(0.4))
                    .frame(width: 36, height: 36)

                Image(systemName: icon)
                    .foregroundStyle(Color.sage500)
                    .font(.system(size: 16, weight: .semibold))
            }

            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(titleColor)

            Spacer()

            accessory()
        }
    }
}

private struct ExportSelection {
    var includeStories = true
    var includeAttempts = true
    var includeJobs = false
    var includeQuestions = false

    var hasSelection: Bool {
        includeStories || includeAttempts || includeJobs || includeQuestions
    }
}

private struct ExportOptionsSheet: View {
    @Binding var selection: ExportSelection
    @Binding var format: ExportFormat
    let isGenerating: Bool
    let onExport: () -> Void

    var body: some View {
        NavigationStack {
            ZStack {
                Color.cream50.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        SectionHeader(title: "Export Options")

                        CardContainer(backgroundColor: Color.surfaceWhite, cornerRadius: 22, showShadow: false) {
                            VStack(spacing: 12) {
                                ExportCheckboxRow(title: "Stories", isOn: $selection.includeStories)
                                Divider().opacity(0.6)
                                ExportCheckboxRow(title: "Attempts", isOn: $selection.includeAttempts)
                                Divider().opacity(0.6)
                                ExportCheckboxRow(title: "Jobs", isOn: $selection.includeJobs)
                                Divider().opacity(0.6)
                                ExportCheckboxRow(title: "Questions", isOn: $selection.includeQuestions)
                            }
                        }

                        SectionHeader(title: "Export Format")

                        CardContainer(backgroundColor: Color.surfaceWhite, cornerRadius: 22, showShadow: false) {
                            Picker("Export Format", selection: $format) {
                                ForEach(ExportFormat.allCases) { exportFormat in
                                    Text(exportFormat.title).tag(exportFormat)
                                }
                            }
                            .pickerStyle(.segmented)
                        }

                        PrimaryCTAButton(title: isGenerating ? "Generating…" : "Export", systemImage: "square.and.arrow.up") {
                            onExport()
                        }
                        .disabled(isGenerating || !selection.hasSelection)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 24)
                }
            }
            .navigationTitle("Export")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

private struct ExportCheckboxRow: View {
    let title: String
    @Binding var isOn: Bool

    var body: some View {
        Button {
            isOn.toggle()
        } label: {
            HStack {
                Image(systemName: isOn ? "checkmark.square.fill" : "square")
                    .foregroundStyle(isOn ? Color.sage500 : Color.ink400)
                Text(title)
                    .foregroundStyle(Color.ink900)
                Spacer()
            }
            .font(.subheadline.weight(.semibold))
        }
        .buttonStyle(.plain)
    }
}
