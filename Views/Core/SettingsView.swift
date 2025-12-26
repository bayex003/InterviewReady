// Manual test checklist:
// - Pro: tap Export -> label changes to Generating... and button disabled -> share sheet appears
// - Tap Export repeatedly quickly -> only one share sheet
// - Force export failure (simulate generateExportFile returning nil) -> alert shows
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

    // Restore Purchases
    @State private var isRestoring = false
    @State private var restoreMessage: String?
    @State private var showRestoreAlert = false
    @State private var restoreAlertTitle = ""

    // Export
    @State private var showShareSheet = false
    @State private var shareItems: [Any] = []
    @State private var isGeneratingExport = false
    @State private var showExportErrorAlert = false

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
                proSection
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
            .sheet(isPresented: $showPaywall) {
                PaywallView()
                    .environmentObject(purchaseManager)
            }
            .sheet(isPresented: $showShareSheet, onDismiss: {
                shareItems = []
            }) {
                ShareSheet(items: shareItems)
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
            .alert("Export failed", isPresented: $showExportErrorAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("We couldn’t generate the export file. Please try again.")
            }
            .alert(restoreAlertTitle, isPresented: $showRestoreAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                if let restoreMessage {
                    Text(restoreMessage)
                }
            }
        }
    }

    // MARK: - Sections (split up for compiler)

    private var proSection: some View {
        Section("Pro") {
            if purchaseManager.isPro {
                HStack {
                    Text("InterviewReady Pro")
                    Spacer()
                    Text("Active")
                        .foregroundStyle(.secondary)
                }
            } else {
                Button {
                    showPaywall = true
                } label: {
                    HStack {
                        Text("Upgrade to Pro")
                        Spacer()
                    }
                }

                Button {
                    restorePurchases()
                } label: {
                    HStack {
                        Text("Restore Purchases")
                        Spacer()
                    }
                }
                .disabled(isRestoring)
            }
        } footer: {
            if isRestoring {
                Text("Restoring…")
            }
        }
    }

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
            Button {
                exportAllDataTapped()
            } label: {
                HStack {
                    Image(systemName: "square.and.arrow.up")
                        .foregroundStyle(Color.sage500)
                    Text(isGeneratingExport ? "Generating Export…" : "Export All Data")
                        .foregroundStyle(Color.ink900)
                }
            }
            .buttonStyle(.plain)
            .disabled(isGeneratingExport)
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

    @MainActor
    private func exportAllDataTapped() {
        guard !isGeneratingExport else { return }
        isGeneratingExport = true

        if let exportURL = DataExportManager.generateExportFile(context: modelContext) {
            shareItems = [exportURL]
            showShareSheet = true
        } else {
            showExportErrorAlert = true
        }

        isGeneratingExport = false
    }

    private func restorePurchases() {
        guard !isRestoring else { return }
        isRestoring = true

        Task {
            await purchaseManager.restore()
            await purchaseManager.refreshEntitlements()

            await MainActor.run {
                isRestoring = false
                if purchaseManager.isPro {
                    restoreAlertTitle = "Restored"
                    restoreMessage = "Pro unlocked."
                } else {
                    restoreAlertTitle = "No purchases found"
                    restoreMessage = "We couldn’t find an active subscription."
                }
                showRestoreAlert = true
            }
        }
    }
}
