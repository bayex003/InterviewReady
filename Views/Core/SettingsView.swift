import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var purchaseManager: PurchaseManager
    @EnvironmentObject private var dataController: AppDataController

    // Notification State
    @AppStorage("isDailyReminderEnabled") private var isDailyReminderEnabled = false
    @AppStorage("dailyReminderTime") private var dailyReminderTime: Double = 32400 // Default 9:00 AM

    // Feedback configuration
    private let supportEmail = "support@example.com"
    private let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"

    // Alerts
    @State private var showResetConfirmation = false
    @State private var showResetSuccess = false

    // Paywall
    @State private var showPaywall = false

    // Export (only computed for Pro users)
    @State private var exportURL: URL?

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
            List {
                remindersSection
                dataManagementSection
                feedbackSection
                aboutSection
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .onAppear {
                prepareExportIfNeeded()
            }
            .onChange(of: purchaseManager.isPro) { _, _ in
                prepareExportIfNeeded()
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView()
                    .environmentObject(purchaseManager)
            }
            .alert("Reset App Data?", isPresented: $showResetConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Delete Everything", role: .destructive) {
                    resetApp()
                }
            } message: {
                Text("This will permanently delete all your Jobs and Stories. This action cannot be undone.")
            }
            .alert("Data Reset", isPresented: $showResetSuccess) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Your app has been reset to a clean state.")
            }
        }
    }

    // MARK: - Sections (split up for compiler)

    private var remindersSection: some View {
        Section("Reminders") {
            Toggle("Daily Practice Reminder", isOn: $isDailyReminderEnabled)
                .tint(Color.sage500)
                .onChange(of: isDailyReminderEnabled) { _, newValue in
                    if newValue {
                        NotificationManager.shared.requestPermission { granted in
                            if !granted { isDailyReminderEnabled = false }
                        }
                    }
                    scheduleNotification()
                }

            if isDailyReminderEnabled {
                DatePicker("Time", selection: reminderTimeBinding, displayedComponents: .hourAndMinute)
            }
        }
    }

    private var dataManagementSection: some View {
        Section {
            exportRow

            Button(role: .destructive) {
                showResetConfirmation = true
            } label: {
                HStack {
                    Image(systemName: "trash")
                    Text("Reset All Data")
                }
            }
        } header: {
            Text("Data Management")
        } footer: {
            if !purchaseManager.isPro {
                Text("Export is a Pro feature.")
            }
        }
    }

    @ViewBuilder
    private var exportRow: some View {
        if purchaseManager.isPro {
            ShareLink(item: exportURL ?? FileManager.default.temporaryDirectory) {
                HStack {
                    Image(systemName: "square.and.arrow.up")
                        .foregroundStyle(Color.sage500)
                    Text("Export All Data")
                        .foregroundStyle(Color.ink900)
                }
            }
        } else {
            Button {
                showPaywall = true
            } label: {
                HStack {
                    Image(systemName: "square.and.arrow.up")
                        .foregroundStyle(Color.sage500)
                    Text("Export All Data")
                        .foregroundStyle(Color.ink900)
                }
            }
            .buttonStyle(.plain)
        }
    }

    private var feedbackSection: some View {
        Section("Feedback") {
            let mailto = "mailto:\(supportEmail)?subject=InterviewReady%20Feedback%20(v\(appVersion))"
            if let url = URL(string: mailto) {
                Link(destination: url) {
                    HStack {
                        Image(systemName: "envelope.fill")
                            .foregroundStyle(Color.sage500)
                        Text("Send Feedback / Bug Report")
                            .foregroundStyle(Color.ink900)
                    }
                }
            } else {
                // Fallback (should almost never happen)
                HStack {
                    Image(systemName: "envelope.fill")
                        .foregroundStyle(Color.sage500)
                    Text("Send Feedback / Bug Report")
                        .foregroundStyle(Color.ink900)
                    Spacer()
                }
            }
        }
    }

    private var aboutSection: some View {
        Section("About") {
            HStack {
                Text("Version")
                Spacer()
                Text(appVersion)
                    .foregroundStyle(.secondary)
            }
            HStack {
                Text("iCloud Sync")
                Spacer()
                Text(purchaseManager.isPro && dataController.isUsingCloud ? "On" : "Off")
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Helpers

    private func prepareExportIfNeeded() {
        guard purchaseManager.isPro else {
            exportURL = nil
            return
        }
        if exportURL == nil {
            exportURL = DataExportManager.generateExportFile(context: modelContext)
        }
    }

    private func scheduleNotification() {
        let date = Date(timeIntervalSince1970: dailyReminderTime)
        NotificationManager.shared.scheduleDailyReminder(isEnabled: isDailyReminderEnabled, time: date)
    }

    private func resetApp() {
        do {
            try modelContext.delete(model: Job.self)
            try modelContext.delete(model: Story.self)
            try modelContext.save()
            showResetSuccess = true
        } catch {
            print("Failed to reset: \(error)")
        }
    }
}
