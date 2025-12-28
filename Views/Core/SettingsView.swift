// SettingsView.swift (COMPLETE REPLACEMENT)

import SwiftUI
import SwiftData

enum ExportFormat: String, CaseIterable, Identifiable {
    case csv = "CSV"
    case rawText = "Raw Text"

    var id: String { rawValue }
    var title: String { rawValue }
}

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var purchaseManager: PurchaseManager
    @EnvironmentObject private var dataController: AppDataController

    // Preferences
    @AppStorage("isHapticFeedbackEnabled") private var isHapticFeedbackEnabled = true
    @AppStorage("isSystemThemeMatchEnabled") private var isSystemThemeMatchEnabled = true

    // Notification State
    @AppStorage("isDailyReminderEnabled") private var isDailyReminderEnabled = false
    @AppStorage("dailyReminderTime") private var dailyReminderTime: Double = 32400 // 9:00 AM

    // Alerts
    @State private var showResetConfirmation = false
    @State private var showResetSuccess = false
    @State private var showExportErrorAlert = false
    @State private var showExportSelectionAlert = false
    @State private var showReminderPrompt = false

    // Paywall
    @State private var showPaywall = false
    @State private var exportGateMessage: String?

    // Export
    @State private var showExportOptions = false
    @State private var showShareSheet = false
    @State private var shareItems: [Any] = []
    @State private var isGeneratingExport = false
    @State private var exportSelection = ExportSelection()
    @State private var exportFormat: ExportFormat = .csv

    private var proGate: ProGatekeeper {
        ProGatekeeper(isPro: { purchaseManager.isPro }, presentPaywall: { showPaywall = true })
    }

    private var reminderTimeBinding: Binding<Date> {
        Binding(
            get: { Date(timeIntervalSince1970: dailyReminderTime) },
            set: { newDate in
                dailyReminderTime = newDate.timeIntervalSince1970
                if isDailyReminderEnabled {
                    scheduleNotification()
                }
            }
        )
    }

    var body: some View {
        ZStack {
            Color.cream50.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 22) {
                    header

                    proCard

                    appPreferencesCard

                    remindersCard

                    dataManagementCard
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 120)
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
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
        .sheet(isPresented: $showShareSheet, onDismiss: { shareItems = [] }) {
            ShareSheet(items: shareItems)
        }
        .alert("Clear all data?", isPresented: $showResetConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete Everything", role: .destructive) {
                resetApp()
            }
        } message: {
            Text("This will permanently delete your jobs, stories, questions, and practise attempts. This action cannot be undone.")
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
        .alert("Enable daily reminder?", isPresented: $showReminderPrompt) {
            Button("Not Now", role: .cancel) {
                isDailyReminderEnabled = false
                scheduleNotification()
            }
            Button("Allow Reminders") {
                NotificationManager.shared.requestPermission { granted in
                    if granted {
                        scheduleNotification()
                    } else {
                        isDailyReminderEnabled = false
                    }
                }
            }
        } message: {
            Text("InterviewReady can send a daily practise reminder at your chosen time.")
        }
    }

    // MARK: - UI

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Settings")
                .font(.largeTitle.bold())
                .foregroundStyle(Color.ink900)

            Text("Manage your experience, reminders, and data.")
                .font(.subheadline)
                .foregroundStyle(Color.ink600)
        }
    }

    private var proCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Pro")
                .font(.headline)
                .foregroundStyle(Color.ink900)

            CardContainer(backgroundColor: Color.surfaceWhite, cornerRadius: 22, showShadow: false) {
                VStack(alignment: .leading, spacing: 14) {
                    HStack(alignment: .top, spacing: 12) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 14)
                                .fill(Color.sage100)
                                .frame(width: 48, height: 48)

                            Image(systemName: "sparkles")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundStyle(Color.sage500)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text(purchaseManager.isPro ? "InterviewReady Pro" : "Unlock Pro Features")
                                .font(.headline)
                                .foregroundStyle(Color.ink900)

                            Text("Review your answers, export your data, scan notes into stories, and unlock unlimited custom questions.")
                                .font(.subheadline)
                                .foregroundStyle(Color.ink600)
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        Spacer()

                        Chip(title: purchaseManager.isPro ? "Active" : "Pro", isSelected: true)
                    }

                    if purchaseManager.isPro {
                        Text("You’re on Pro. Thank you for supporting InterviewReady.")
                            .font(.subheadline)
                            .foregroundStyle(Color.ink600)
                    } else {
                        PrimaryCTAButton(title: "Upgrade to Pro") {
                            showPaywall = true
                        }
                    }
                }
            }
        }
    }

    private var appPreferencesCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("App Preferences")
                .font(.headline)
                .foregroundStyle(Color.ink900)

            CardContainer(backgroundColor: Color.surfaceWhite, cornerRadius: 22, showShadow: false) {
                VStack(spacing: 12) {
                    SettingsRow(icon: "wave.3.right", title: "Haptic Feedback") {
                        Toggle("", isOn: $isHapticFeedbackEnabled)
                            .labelsHidden()
                            .tint(Color.sage500)
                    }

                    Divider().opacity(0.6)

                    SettingsRow(icon: "circle.lefthalf.filled", title: "System Theme Match") {
                        Toggle("", isOn: $isSystemThemeMatchEnabled)
                            .labelsHidden()
                            .tint(Color.sage500)
                    }
                }
            }
        }
    }

    private var remindersCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Reminders")
                .font(.headline)
                .foregroundStyle(Color.ink900)

            CardContainer(backgroundColor: Color.surfaceWhite, cornerRadius: 22, showShadow: false) {
                VStack(spacing: 12) {
                    SettingsRow(icon: "bell", title: "Daily Practise") {
                        Toggle("", isOn: $isDailyReminderEnabled)
                            .labelsHidden()
                            .tint(Color.sage500)
                            .onChange(of: isDailyReminderEnabled) { _, newValue in
                                if newValue {
                                    showReminderPrompt = true
                                } else {
                                    scheduleNotification()
                                }
                            }
                    }

                    if isDailyReminderEnabled {
                        Divider().opacity(0.6)

                        SettingsRow(icon: "clock", title: "Reminder Time") {
                            DatePicker("", selection: reminderTimeBinding, displayedComponents: .hourAndMinute)
                                .labelsHidden()
                        }
                    }
                }
            }
        }
    }

    private var dataManagementCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Data Management")
                .font(.headline)
                .foregroundStyle(Color.ink900)

            CardContainer(backgroundColor: Color.surfaceWhite, cornerRadius: 22, showShadow: false) {
                VStack(spacing: 12) {
                    Button {
                        proGate.requirePro(.export) {
                            showExportOptions = true
                        } onBlocked: {
                            exportGateMessage = ProGate.export.inlineMessage
                        }
                    } label: {
                        SettingsRow(icon: "square.and.arrow.up", title: "Export My Data") {
                            if purchaseManager.isPro {
                                Image(systemName: "chevron.right")
                                    .foregroundStyle(Color.ink400)
                            } else {
                                HStack(spacing: 6) {
                                    Image(systemName: "lock.fill")
                                        .font(.caption)
                                        .foregroundStyle(Color.ink400)
                                    Text("Pro")
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(Color.ink400)
                                }
                            }
                        }
                    }
                    .buttonStyle(.plain)

#if DEBUG
                    Divider().opacity(0.6)

                    Button {
                        exportAnalyticsLog()
                    } label: {
                        SettingsRow(icon: "waveform.path.ecg", title: "Export Analytics Log") {
                            Image(systemName: "chevron.right")
                                .foregroundStyle(Color.ink400)
                        }
                    }
                    .buttonStyle(.plain)
#endif

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

            VStack(alignment: .leading, spacing: 6) {
                if !purchaseManager.isPro {
                    Text(exportGateMessage ?? ProGate.export.inlineMessage)
                        .font(.footnote)
                        .foregroundStyle(Color.ink500)
                }

                Text("Your data is stored locally on this device. Exporting creates CSV or raw text files for sharing.")
                    .font(.footnote)
                    .foregroundStyle(Color.ink500)
            }
        }
    }

    // MARK: - Actions

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

            // ✅ Clear legacy JobsStore persisted cache without referencing JobsStore at all
            UserDefaults.standard.removeObject(forKey: "jobs_store_v1")

            showResetSuccess = true
        } catch {
            print("Failed to reset: \(error)")
        }
    }

    private func exportSelectedData() {
        guard !isGeneratingExport else { return }
        guard exportSelection.hasSelection else {
            showExportSelectionAlert = true
            return
        }

        isGeneratingExport = true
        Task {
            await exportSelectedDataAsync()
        }
    }

    @MainActor
    private func exportSelectedDataAsync() async {
        defer { isGeneratingExport = false }

        do {
            let exportDirectory = try makeExportDirectory()

            // ✅ Fetch in small, separate calls (prevents type-checker meltdown)
            let stories = try fetchStoriesIfNeeded()
            let questions = try fetchQuestionsIfNeeded()
            let attempts = try fetchAttemptsIfNeeded()
            let jobs = try fetchJobsIfNeeded()

            let urls = try buildExportFiles(
                exportDirectory: exportDirectory,
                stories: stories,
                questions: questions,
                attempts: attempts,
                jobs: jobs
            )

            guard !urls.isEmpty else {
                showExportErrorAlert = true
                return
            }

            shareItems = urls
            showExportOptions = false
            showShareSheet = true
        } catch {
            print("Export failed: \(error)")
            showExportErrorAlert = true
        }
    }

    private func exportAnalyticsLog() {
        do {
            let url = try AnalyticsEventLogger.shared.exportLogFile()
            shareItems = [url]
            showShareSheet = true
        } catch {
            showExportErrorAlert = true
        }
    }

    // MARK: - Export helpers (ADD these below exportSelectedDataAsync)

    @MainActor
    private func makeExportDirectory() throws -> URL {
        let exportDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("InterviewReadyExport_\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: exportDirectory, withIntermediateDirectories: true)
        return exportDirectory
    }

    @MainActor
    private func fetchStoriesIfNeeded() throws -> [Story] {
        guard exportSelection.includeStories else { return [] }
        return try modelContext.fetch(
            FetchDescriptor<Story>(sortBy: [SortDescriptor(\.lastUpdated, order: .reverse)])
        )
    }

    @MainActor
    private func fetchQuestionsIfNeeded() throws -> [Question] {
        guard exportSelection.includeQuestions || exportSelection.includeAttempts else {
            return []
        }
        let questions = try modelContext.fetch(
            FetchDescriptor<Question>(sortBy: [SortDescriptor(\.updatedAt, order: .reverse)])
        )
        return questions
    }

    @MainActor
    private func fetchAttemptsIfNeeded() throws -> [PracticeAttempt] {
        guard exportSelection.includeAttempts else { return [] }
        return try modelContext.fetch(
            FetchDescriptor<PracticeAttempt>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)])
        )
    }

    @MainActor
    private func fetchJobsIfNeeded() throws -> [Job] {
        guard exportSelection.includeJobs else { return [] }
        return try modelContext.fetch(
            FetchDescriptor<Job>(sortBy: [SortDescriptor(\.dateApplied, order: .reverse)])
        )
    }

    @MainActor
    private func buildExportFiles(
        exportDirectory: URL,
        stories: [Story],
        questions: [Question],
        attempts: [PracticeAttempt],
        jobs: [Job]
    ) throws -> [URL] {
        var urls: [URL] = []

        switch exportFormat {
        case .csv:
            if exportSelection.includeStories {
                let headers = ["story_id","title","tags","category","situation","task","action","result","notes","updated_at"]
                let rows = stories.map { s in
                    [
                        String(describing: s.id),
                        s.title,
                        StoryStore.sortedTags(s.tags).joined(separator: ", "),
                        s.category,
                        s.situation,
                        s.task,
                        s.action,
                        s.result,
                        s.notes,
                        isoString(s.lastUpdated)
                    ]
                }
                if let url = writeCSV(fileName: "interviewready_stories.csv", headers: headers, rows: rows, to: exportDirectory) {
                    urls.append(url)
                }
            }

            if exportSelection.includeAttempts {
                let headers = ["question_id","question_text_snapshot","answer_text","created_at","duration_seconds","has_audio"]
                let rows = attempts.map { a in
                    return [
                        a.questionId.map { String(describing: $0) } ?? "",
                        a.questionTextSnapshot,
                        a.notes ?? "",
                        isoString(a.createdAt),
                        a.durationSeconds.map(String.init) ?? "",
                        a.audioPath == nil ? "false" : "true"
                    ]
                }
                if let url = writeCSV(fileName: "interviewready_attempts.csv", headers: headers, rows: rows, to: exportDirectory) {
                    urls.append(url)
                }
            }

            if exportSelection.includeJobs {
                let headers = ["job_id","company","role","stage","location","salary","date_applied","next_interview","notes"]
                let rows = jobs.map { j in
                    [
                        String(describing: j.id),
                        j.companyName,
                        j.roleTitle,
                        j.stage.rawValue,
                        j.location ?? "",
                        j.salary ?? "",
                        isoString(j.dateApplied),
                        j.nextInterviewDate.map(isoString) ?? "",
                        j.generalNotes
                    ]
                }
                if let url = writeCSV(fileName: "interviewready_jobs.csv", headers: headers, rows: rows, to: exportDirectory) {
                    urls.append(url)
                }
            }

            if exportSelection.includeQuestions {
                let headers = ["question_id","question_text","category","is_user_created","updated_at"]
                let rows = questions
                    .filter { $0.isCustom }
                    .map { q in
                        [
                            String(describing: q.id),
                            q.text,
                            q.category,
                            q.isCustom ? "true" : "false",
                            isoString(q.updatedAt)
                        ]
                    }

                if let url = writeCSV(fileName: "interviewready_questions.csv", headers: headers, rows: rows, to: exportDirectory) {
                    urls.append(url)
                }
            }

        case .rawText:
            let text = buildRawTextExport(
                jobs: jobs,
                stories: stories,
                attempts: attempts,
                questions: questions.filter { $0.isCustom },
                includeJobs: exportSelection.includeJobs,
                includeStories: exportSelection.includeStories,
                includeAttempts: exportSelection.includeAttempts,
                includeQuestions: exportSelection.includeQuestions
            )

            let fileURL = exportDirectory.appendingPathComponent("interviewready_export.txt")
            try text.write(to: fileURL, atomically: true, encoding: .utf8)
            urls = [fileURL]
        }

        if let analyticsURL = try? AnalyticsEventLogger.shared.exportLogFile() {
            urls.append(analyticsURL)
        }

        return urls
    }


    // MARK: - Export Helpers

    private func isoString(_ date: Date) -> String {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f.string(from: date)
    }

    private func buildRawTextExport(
        jobs: [Job],
        stories: [Story],
        attempts: [PracticeAttempt],
        questions: [Question],
        includeJobs: Bool,
        includeStories: Bool,
        includeAttempts: Bool,
        includeQuestions: Bool
    ) -> String {
        let df = DateFormatter()
        df.dateStyle = .medium
        df.timeStyle = .short

        var out: [String] = []
        out.append("InterviewReady Export")
        out.append("Generated: \(df.string(from: Date()))")
        out.append("")

        if includeJobs {
            out.append("JOBS")
            if jobs.isEmpty { out.append("No jobs available\n") }
            for (i, j) in jobs.enumerated() {
                out.append("\(i + 1)) \(j.companyName) — \(j.roleTitle)")
                out.append("Stage: \(j.stage.rawValue)")
                out.append("Location: \(j.location ?? "None")")
                out.append("Salary: \(j.salary ?? "None")")
                out.append("Applied: \(isoString(j.dateApplied))")
                out.append("Next Interview: \(j.nextInterviewDate.map(isoString) ?? "None")")
                out.append("")
            }
        }

        if includeStories {
            out.append("STORIES")
            if stories.isEmpty { out.append("No stories available\n") }
            for (i, s) in stories.enumerated() {
                out.append("\(i + 1)) \(s.title)")
                out.append("Tags: \(StoryStore.sortedTags(s.tags).joined(separator: ", "))")
                out.append("Category: \(s.category)")
                out.append("Updated: \(isoString(s.lastUpdated))")
                out.append("")
            }
        }

        if includeAttempts {
            out.append("ATTEMPTS")
            if attempts.isEmpty { out.append("No attempts available\n") }
            for (i, a) in attempts.enumerated() {
                out.append("\(i + 1)) \(isoString(a.createdAt))")
                out.append("Question ID: \(a.questionId.map { String(describing: $0) } ?? "None")")
                out.append("Question: \(a.questionTextSnapshot)")
                out.append("Answer: \(a.notes ?? "None")")
                out.append("Duration (seconds): \(a.durationSeconds.map(String.init) ?? "None")")
                out.append("Has Audio: \(a.audioPath == nil ? "No" : "Yes")")
                out.append("")
            }
        }

        if includeQuestions {
            out.append("QUESTIONS")
            if questions.isEmpty { out.append("No questions available\n") }
            for (i, q) in questions.enumerated() {
                out.append("\(i + 1)) \(q.text)")
                out.append("Category: \(q.category)")
                out.append("Updated: \(isoString(q.updatedAt))")
                out.append("")
            }
        }

        return out.joined(separator: "\n")
    }

    private func writeCSV(
        fileName: String,
        headers: [String],
        rows: [[String]],
        to directory: URL
    ) -> URL? {
        var lines: [String] = []
        lines.append(headers.map(csvEscaped).joined(separator: ","))
        for row in rows {
            lines.append(row.map(csvEscaped).joined(separator: ","))
        }
        let csv = lines.joined(separator: "\n")
        let url = directory.appendingPathComponent(fileName)
        do {
            try csv.write(to: url, atomically: true, encoding: .utf8)
            return url
        } catch {
            print("Failed to write CSV: \(error)")
            return nil
        }
    }

    private func csvEscaped(_ value: String) -> String {
        let needsQuotes = value.contains(",") || value.contains("\"") || value.contains("\n") || value.contains("\r")
        let escaped = value.replacingOccurrences(of: "\"", with: "\"\"")
        return needsQuotes ? "\"\(escaped)\"" : escaped
    }
}

// MARK: - Small UI pieces

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
    var includeJobs = true
    var includeQuestions = true

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

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 18) {
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
                                ForEach(ExportFormat.allCases) { f in
                                    Text(f.title).tag(f)
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
        Button { isOn.toggle() } label: {
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
