import SwiftUI
import SwiftData

struct NewStoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var purchaseManager: PurchaseManager

    @Query(sort: \Story.lastUpdated, order: .reverse) private var stories: [Story]
    @Query(sort: \Job.dateApplied, order: .reverse) private var jobs: [Job]

    let story: Story?

    @State private var title: String
    @State private var selectedTags: Set<String>
    @State private var situation: String
    @State private var task: String
    @State private var action: String
    @State private var result: String
    @State private var notes: String
    @State private var manualScanDraft: String
    

    @State private var selectedJob: Job?

    @State private var newTagName = ""
    @State private var isAddTagPresented = false

    // Scan flow
    @State private var isProcessingScan = false
    @State private var scannedText = ""
    @State private var scanInsertFields: [ScanInsertPickerView.Field] = []
    @State private var starDraft = StarPreviewDraft.empty

    // Single-sheet state (prevents sheet stacking / jank)
    @State private var activeSheet: ActiveSheet?

    // Alerts (empty OCR, simulator message, errors)
    @State private var activeAlert: ScanAlert?

    @State private var scanGateMessage: String?

    private var proGate: ProGatekeeper {
        ProGatekeeper(isPro: { purchaseManager.isPro }, presentPaywall: { activeSheet = .paywall })
    }

    init(story: Story? = nil, suggestedTitle: String? = nil) {
        self.story = story
        let baseTitle = story?.title ?? ""
        let resolvedTitle = baseTitle.isEmpty ? (suggestedTitle ?? "") : baseTitle
        _title = State(initialValue: resolvedTitle)
        let initialTags = NewStoryView.initialTagSelection(for: story)
        _selectedTags = State(initialValue: Set(initialTags))
        _situation = State(initialValue: story?.situation ?? "")
        _task = State(initialValue: story?.task ?? "")
        _action = State(initialValue: story?.action ?? "")
        _result = State(initialValue: story?.result ?? "")
        _notes = State(initialValue: story?.notes ?? "")
        _manualScanDraft = State(initialValue: "")
        _selectedJob = State(initialValue: story?.linkedJob)
    }

    enum ActiveSheet: Identifiable {
        case paywall
        case scanner
        case review
        case starPreview
        case insertPicker

        var id: String {
            switch self {
            case .paywall: return "paywall"
            case .scanner: return "scanner"
            case .review: return "review"
            case .starPreview: return "starPreview"
            case .insertPicker: return "insertPicker"
            }
        }
    }

    struct ScanAlert: Identifiable {
        let id = UUID()
        let title: String
        let message: String
    }

    private var isEditing: Bool {
        story != nil
    }

    private var hasStarContent: Bool {
        [situation, task, action, result].contains { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    }

    private var canSave: Bool {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        return !isProcessingScan && (!trimmedTitle.isEmpty || hasStarContent)
    }

    private var availableTags: [String] {
        let storeTags = StoryStore(stories: stories).allTags
        let combined = storeTags + Array(selectedTags)
        return StoryStore.sortedTags(combined)
    }

    private var selectedTagsSorted: [String] {
        StoryStore.sortedTags(Array(selectedTags))
    }

    private var suggestedTags: [String] {
        let storeTags = StoryStore.sortedTags(StoryStore(stories: stories).allTags)
        return storeTags.filter { !selectedTags.contains($0) }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                titleSection
                tagsSection
                scanCard

                if !purchaseManager.isPro {
                    Text(scanGateMessage ?? ProGate.scanNotes.inlineMessage)
                        .font(.footnote)
                        .foregroundStyle(Color.ink500)
                }
                starSection
                notesSection

                if !manualScanDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    manualDraftSection
                }

                jobLinkSection
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 140)
        }
        .tapToDismissKeyboard()
        .navigationTitle(isEditing ? "Edit Story" : "New Story")
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            actionBar
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button(isEditing ? "Back" : "Cancel") { dismiss() }
                    .foregroundStyle(Color.ink500)
            }

            ToolbarItem(placement: .topBarTrailing) {
                Button("Save") { saveStory() }
                    .font(.headline)
                    .foregroundStyle(Color.sage500)
                    .disabled(!canSave)
            }
        }
        .sheet(item: $activeSheet) { sheet in
            switch sheet {
            case .paywall:
                PaywallView()
                    .environmentObject(purchaseManager)

            case .scanner:
                DocumentScannerView(
                    onSuccess: { images in
                        activeSheet = nil
                        runOCR(images: images)
                    },
                    onCancel: {
                        activeSheet = nil
                        isProcessingScan = false
                    },
                    onError: { _ in
                        activeSheet = nil
                        isProcessingScan = false
                        activeAlert = ScanAlert(
                            title: "Scan failed",
                            message: "We couldn’t scan that page. Please try again."
                        )
                    }
                )

            case .review:
                ScanReviewView(
                    scannedText: scannedText,
                    onAssistSTAR: {
                        starDraft = StarPreviewDraft.from(scannedText: scannedText)
                        activeSheet = .starPreview
                    },
                    onRawNotes: {
                        scanInsertFields = [.notes]
                        activeSheet = .insertPicker
                    },
                    onManual: {
                        scanInsertFields = [.manualDraft]
                        activeSheet = .insertPicker
                    }
                )

            case .starPreview:
                StarPreviewInsertView(
                    draft: starDraft,
                    onInsert: { updatedDraft in
                        situation = updatedDraft.situation
                        task = updatedDraft.task
                        action = updatedDraft.action
                        result = updatedDraft.result
                        activeSheet = nil
                    }
                )

            case .insertPicker:
                ScanInsertPickerView(
                    scannedText: scannedText,
                    availableFields: scanInsertFields,
                    situation: $situation,
                    task: $task,
                    action: $action,
                    result: $result,
                    notes: $notes,
                    manualDraft: $manualScanDraft
                )
            }
        }
        .alert(item: $activeAlert) { alert in
            Alert(
                title: Text(alert.title),
                message: Text(alert.message),
                dismissButton: .default(Text("OK"))
            )
        }
    }

    private var actionBar: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                Button(isEditing ? "Back" : "Cancel") {
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
                    saveStory()
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

    private var titleSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("TITLE")
                .font(.caption)
                .foregroundStyle(Color.ink500)

            TextField("e.g. Project Phoenix Launch", text: $title)
                .font(.title3.weight(.semibold))
                .foregroundStyle(Color.ink900)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)

            if !canSave && !isProcessingScan {
                Text("Add a title or at least one STAR field to save.")
                    .font(.caption)
                    .foregroundStyle(Color.ink400)
            }

            Divider()
        }
    }

    private var tagsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("TAGS")
                    .font(.caption)
                    .foregroundStyle(Color.ink500)

                Spacer()

                Button {
                    newTagName = ""
                    isAddTagPresented = true
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "plus")
                        Text("Add Tag")
                    }
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.sage500)
                }
                .buttonStyle(.plain)
            }

            // Selected tags (removable)
            if !selectedTags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(selectedTagsSorted, id: \.self) { tag in
                            SelectedTagChip(title: tag) {
                                toggleTag(tag)
                            }
                        }
                    }
                }
            }

            // Suggested/existing tags (tap to select)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(suggestedTags, id: \.self) { tag in
                        SuggestedTagChip(title: tag) {
                            toggleTag(tag)
                        }
                    }
                }
            }
        }
        .alert("Add tag", isPresented: $isAddTagPresented) {
            TextField("Tag name", text: $newTagName)

            Button("Cancel", role: .cancel) {
                newTagName = ""
            }

            Button("Add") {
                addNewTag()
            }
        } message: {
            Text("Create a custom tag for this story.")
        }
    }


    private var scanCard: some View {
        Button {
            handleScanTapped()
        } label: {
            CardContainer(backgroundColor: Color.sage100.opacity(0.2), cornerRadius: 18, showShadow: false) {
                HStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(Color.sage500)
                            .frame(width: 44, height: 44)

                        Image(systemName: "doc.text.viewfinder")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(Color.white)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Scan Handwritten Note")
                            .font(.headline)
                            .foregroundStyle(Color.ink900)

                        Text("Auto-fill story details from paper")
                            .font(.caption)
                            .foregroundStyle(Color.ink500)
                    }

                    Spacer()

                    if isProcessingScan {
                        ProgressView()
                    } else {
                        Image(systemName: "chevron.right")
                            .foregroundStyle(Color.ink400)
                    }
                }
            }
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(style: StrokeStyle(lineWidth: 1, dash: [6]))
                    .foregroundStyle(Color.sage500.opacity(0.5))
            )
        }
        .buttonStyle(.plain)
        .disabled(isProcessingScan)
        .accessibilityLabel("Scan handwritten note")
        .accessibilityHint("Uses the camera to capture and extract text")
    }

    private var starSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                StorySectionHeader(title: "The STAR Method")
                Image(systemName: "info.circle")
                    .foregroundStyle(Color.ink400)
                    .accessibilityHidden(true)
            }

            StarFieldEditor(label: "Situation", symbol: "S", placeholder: "What was the context? Describe the background of the event.", text: $situation)
            StarFieldEditor(label: "Task", symbol: "T", placeholder: "What was your specific goal or the challenge you faced?", text: $task)
            StarFieldEditor(label: "Action", symbol: "A", placeholder: "What did *you* do? Explain your specific steps and contribution.", text: $action)
            StarFieldEditor(label: "Result", symbol: "R", placeholder: "What was the outcome? Quantify if possible (e.g., +20% revenue).", text: $result)
        }
    }

    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("NOTES")
                .font(.caption)
                .foregroundStyle(Color.ink500)

            TextEditor(text: $notes)
                .frame(minHeight: 120)
                .padding(12)
                .background(RoundedRectangle(cornerRadius: 16).fill(Color.surfaceWhite))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.ink200, lineWidth: 1)
                )
        }
    }

    private var manualDraftSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("SCAN DRAFT")
                .font(.caption)
                .foregroundStyle(Color.ink500)

            TextEditor(text: $manualScanDraft)
                .frame(minHeight: 120)
                .padding(12)
                .background(RoundedRectangle(cornerRadius: 16).fill(Color.surfaceWhite))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.ink200, lineWidth: 1)
                )

            Text("Edit this draft or paste into STAR fields as needed.")
                .font(.caption)
                .foregroundStyle(Color.ink500)
        }
    }

    private var jobLinkSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("LINK TO JOB APPLICATION")
                .font(.caption)
                .foregroundStyle(Color.ink500)

            Menu {
                Button("None") { selectedJob = nil }

                if !jobs.isEmpty {
                    Divider()

                    ForEach(jobs) { job in
                        Button("\(job.companyName) · \(job.roleTitle)") {
                            selectedJob = job
                        }
                    }
                }
            } label: {
                HStack {
                    Text(
                        selectedJob.map { "\($0.companyName) · \($0.roleTitle)" }
                        ?? "Select a job application…"
                    )
                    .foregroundStyle(selectedJob == nil ? Color.ink500 : Color.ink900)

                    Spacer()

                    Image(systemName: "chevron.down")
                        .foregroundStyle(Color.ink400)
                }
                .padding(12)
                .background(RoundedRectangle(cornerRadius: 16).fill(Color.surfaceWhite))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.ink200, lineWidth: 1)
                )
            }
            .disabled(jobs.isEmpty)

            if jobs.isEmpty {
                Text("No jobs yet. Add a job to link it here.")
                    .font(.caption)
                    .foregroundStyle(Color.ink400)
            }
        }
    }


    private func toggleTag(_ tag: String) {
        if selectedTags.contains(tag) {
            selectedTags.remove(tag)
        } else {
            selectedTags.insert(tag)
        }
    }

    private func addNewTag() {
        let trimmed = newTagName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        if let existing = availableTags.first(where: { $0.compare(trimmed, options: .caseInsensitive) == .orderedSame }) {
            selectedTags.insert(existing)
            newTagName = ""
            return
        }

        selectedTags.insert(trimmed)
        newTagName = ""
    }

    private func handleScanTapped() {
        guard !isProcessingScan else { return }

        proGate.requirePro(.scanNotes) {
            startScanFlow()
        } onBlocked: {
            scanGateMessage = ProGate.scanNotes.inlineMessage
        }
    }

    private func startScanFlow() {
        #if targetEnvironment(simulator)
        activeAlert = ScanAlert(
            title: "Scanner unavailable",
            message: "Document scanning isn’t supported on the Simulator. Run the app on an iPhone to use Scan Notes."
        )
        #else
        activeSheet = .scanner
        #endif
    }

    private func runOCR(images: [UIImage]) {
        guard !images.isEmpty else {
            activeAlert = ScanAlert(title: "No pages scanned", message: "Try scanning again.")
            return
        }

        isProcessingScan = true

        OCRService.recognizeText(in: images) { result in
            isProcessingScan = false

            switch result {
            case .success(let text):
                scannedText = text
                activeSheet = .review

            case .failure(let error):
                if let ocrError = error as? OCRService.OCRServiceError,
                   ocrError == .noTextFound {
                    activeAlert = ScanAlert(
                        title: "No readable text found",
                        message: "Try a clearer photo with better lighting, or write larger and scan again."
                    )
                } else {
                    activeAlert = ScanAlert(
                        title: "OCR failed",
                        message: "We couldn’t extract text from that scan. Please try again."
                    )
                }
            }
        }
    }

    private func saveStory() {
        guard canSave else { return }
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let resolvedTitle = trimmedTitle.isEmpty ? "Untitled Story" : trimmedTitle
        let normalizedTags = StoryStore.normalizeTags(Array(selectedTags))
        let tagList = StoryStore.sortedTags(normalizedTags)
        let resolvedCategory = tagList.first ?? (story?.category ?? "General")

        if let story {
            story.title = resolvedTitle
            story.category = resolvedCategory
            story.tags = tagList
            story.situation = situation
            story.task = task
            story.action = action
            story.result = result
            story.notes = mergedNotes()
            story.linkedJob = selectedJob
            story.lastUpdated = Date()
        } else {
            let newStory = Story(title: resolvedTitle, category: resolvedCategory)
            newStory.situation = situation
            newStory.task = task
            newStory.action = action
            newStory.result = result
            newStory.notes = mergedNotes()
            newStory.linkedJob = selectedJob
            newStory.lastUpdated = Date()
            modelContext.insert(newStory)
        }

        AnalyticsEventLogger.shared.log(.storySaved)
        dismiss()
    }

    private func mergedNotes() -> String {
        let trimmedDraft = manualScanDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedDraft.isEmpty else { return notes }

        if notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return trimmedDraft
        }

        if notes.contains(trimmedDraft) {
            return notes
        }

        return notes + "\n\n" + trimmedDraft
    }

    private static func initialTagSelection(for story: Story?) -> [String] {
        guard let story else { return [] }
        if !story.tags.isEmpty {
            return story.tags
        }
        if story.category.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return []
        }
        if story.category == "General" {
            return []
        }
        return [story.category]
    }
}

private struct StarFieldEditor: View {
    let label: String
    let symbol: String
    let placeholder: String
    @Binding var text: String
    private var badgeStyle: BadgeStyle {
        switch symbol {
        case "S":
            return BadgeStyle(
                background: Color.sage100,
                foreground: Color.sage500,
                border: Color.sage500.opacity(0.3)
            )
        case "T":
            return BadgeStyle(
                background: Color.ink100.opacity(0.7),
                foreground: Color.ink700,
                border: Color.ink200
            )
        case "A":
            return BadgeStyle(
                background: Color.cream50,
                foreground: Color.ink600,
                border: Color.ink200
            )
        case "R":
            return BadgeStyle(
                background: Color.sage100.opacity(0.55),
                foreground: Color.sage500,
                border: Color.sage500.opacity(0.2)
            )
        default:
            return BadgeStyle(
                background: Color.ink100,
                foreground: Color.ink700,
                border: Color.ink200
            )
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Circle()
                    .fill(badgeStyle.background)
                    .frame(width: 24, height: 24)
                    .overlay(
                        Circle()
                            .stroke(badgeStyle.border, lineWidth: 1)
                    )
                    .overlay(
                        Text(symbol)
                            .font(.caption.bold())
                            .foregroundStyle(badgeStyle.foreground)
                    )

                Text(label)
                    .font(.headline)
                    .foregroundStyle(Color.ink900)
            }

            ZStack(alignment: .topLeading) {
                TextEditor(text: $text)
                    .frame(minHeight: 120)
                    .padding(12)
                    .background(RoundedRectangle(cornerRadius: 16).fill(Color.surfaceWhite))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.ink200, lineWidth: 1)
                    )

                if text.isEmpty {
                    Text(placeholder)
                        .font(.subheadline)
                        .foregroundStyle(Color.ink400)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 20)
                }
            }
        }
    }
}

private struct BadgeStyle {
    let background: Color
    let foreground: Color
    let border: Color
}
private struct StorySectionHeader: View {
    let title: String
    var body: some View {
        Text(title.uppercased())
            .font(.caption)
            .foregroundStyle(Color.ink500)
            .padding(.bottom, 2)
    }
}

private struct SelectedTagChip: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Text(title)
                    .font(.caption.weight(.semibold))
                    .lineLimit(1)
                    .foregroundStyle(Color.ink900)

                Image(systemName: "xmark")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(Color.ink700)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.sage100.opacity(0.75))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.sage500.opacity(0.55), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(title), selected")
    }
}

private struct SuggestedTagChip: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption.weight(.semibold))
                .lineLimit(1)
                .foregroundStyle(Color.ink900)
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color.surfaceWhite)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.ink200, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
    }
}
