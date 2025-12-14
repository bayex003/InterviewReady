import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    // Notification State
    @AppStorage("isDailyReminderEnabled") private var isDailyReminderEnabled = false
    @AppStorage("dailyReminderTime") private var dailyReminderTime: Double = 32400 // Default 9:00 AM
    
    // Feedback configuration
    let supportEmail = "support@example.com"
    let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    
    // Alert State
    @State private var showResetConfirmation = false
    @State private var showResetSuccess = false
    
    private var exportURL: URL {
        if let url = DataExportManager.generateExportFile(context: modelContext) {
            return url
        }
        return FileManager.default.temporaryDirectory
    }
    
    var body: some View {
        NavigationStack {
            List {
                // 1. NEW: Notifications Section
                Section("Reminders") {
                    Toggle("Daily Practice Reminder", isOn: $isDailyReminderEnabled)
                        .tint(Color.sage500)
                        .onChange(of: isDailyReminderEnabled) { _, newValue in
                            if newValue {
                                // Request permission when turned on
                                NotificationManager.shared.requestPermission { granted in
                                    if !granted { isDailyReminderEnabled = false }
                                }
                            }
                            scheduleNotification()
                        }
                    
                    if isDailyReminderEnabled {
                        DatePicker("Time", selection: Binding(
                            get: { Date(timeIntervalSince1970: dailyReminderTime) },
                            set: { newDate in
                                dailyReminderTime = newDate.timeIntervalSince1970
                                scheduleNotification()
                            }
                        ), displayedComponents: .hourAndMinute)
                    }
                }
                
                // 2. Data Management
                Section("Data Management") {
                    ShareLink(item: exportURL) {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                                .foregroundStyle(Color.sage500)
                            Text("Export All Data")
                                .foregroundStyle(Color.ink900)
                        }
                    }
                    
                    Button(role: .destructive) {
                        showResetConfirmation = true
                    } label: {
                        HStack {
                            Image(systemName: "trash")
                            Text("Reset All Data")
                        }
                    }
                }
                
                // 3. Feedback
                Section("Feedback") {
                    Link(destination: URL(string: "mailto:\(supportEmail)?subject=InterviewReady%20Feedback%20(v\(appVersion))")!) {
                        HStack {
                            Image(systemName: "envelope.fill")
                                .foregroundStyle(Color.sage500)
                            Text("Send Feedback / Bug Report")
                                .foregroundStyle(Color.ink900)
                        }
                    }
                }
                
                // 4. About
                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text(appVersion)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
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
