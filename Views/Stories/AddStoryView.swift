import SwiftUI
import SwiftData

struct NewStoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var purchaseManager: PurchaseManager

    let story: Story?

    @State private var title: String
    @State private var selectedTags: Set<String>
    @State private var situation: String
    @State private var task: String
    @State private var action: String
    @State private var result: String
    @State private var notes: String
    @State private var manualScanDraft: String

    @State private var selectedJob: String?

    @State private var customTags: [String]
    @State private var showAddTagAlert = false
    @State private var newTagName = ""

    // Scan flow
    @State private var isProcessingScan = false
    @State private var scannedText = ""
    @State private var scanInsertFields: [ScanInsertPickerView.Field] = []
    @State private var starDraft = StarDraft.empty

    // Single-sheet state (prevents sheet stacking / jank)
    @State private var activeSheet: ActiveSheet?

    // Alerts (empty OCR, simulator message, errors)
    @State private var activeAlert: ScanAlert?

    private let baseTags = ["Leadership", "Conflict", "Technical", "Behavioral", "Strategy", "Problem Solving"]

    init(story: Story? = nil) {
        self.story = story
        _title = State(initialValue: story?.title ?? "")
        let initialTags = NewStoryView.initialTagSelection(for: story)
        _selectedTags = State(initialValue: Set(initialTags))
        _situation = State(initialValue: story?.situation ?? "")
        _task = State(initialValue: story?.task ?? "")
        _action = State(initialValue: story?.action ?? "")
        _result = State(initialValue: story?.result ?? "")
        _notes = State(initialValue: story?.notes ?? "")
        _manualScanDraft = State(initialValue: "")

        let extraTags = initialTags.filter { !baseTags.contains($0) }
        _customTags = State(initialValue: extraTags)
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

    private var availableTags: [String] {
        baseTags + customTags
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                headerBar

                titleSection

                tagsSection

                scanCard

                starSection

                notesSection

                if !manualScanDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    manualDraftSection
                }

                jobLinkSection
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .safeAreaPadding(.bottom, 120)
        }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .sheet(item: $activeSheet) { sheet in
            switch sheet {
            case .paywall:
                PaywallView()
                    .environmentObject(purchaseManager)

            case .scanner:
                DocumentScannerView(
                    onSuccess: { images in
                        // Close scanner, then OCR
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
                        starDraft = StarDraft.from(scannedText: scannedText)
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
                StarPreviewInsertView(draft: starDraft) { updatedDraft in
                    situation = updatedDraft.situation
                    task = updatedDraft.task
                    action = updatedDraft.action
                    result = updatedDraft.result
                }

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

    private var headerBar: some View {
        HStack {
            Button(isEditing ? "Back" : "Cancel") {
                dismiss()
            }
            .foregroundStyle(Color.ink500)

            Spacer()

            Text(isEditing ? "Edit Story" : "New Story")
                .font(.headline)
                .foregroundStyle(Color.ink900)

            Spacer()

            Button("Save") {
                saveStory()
            }
            .font(.headline)
            .foregroundStyle(Color.sage500)
            .disabled(isProcessingScan || title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
    }

    private var titleSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("TITLE")
                .font(.caption)
                .foregroundStyle(Color.ink500)

            TextField("e.g. Project Phoenix Launch", text: $title)
                .font(.title3.weight(.semibold))
                .foregroundStyle(Color.ink900)
                .padding(.vertical, 8)

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
                    showAddTagAlert = true
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "plus")
                        Text("Add Tag")
                    }
                    .font(.caption)
                    .foregroundStyle(Color.sage500)
                }
                .buttonStyle(.plain)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(availableTags, id: \.self) { tag in
                        Chip(title: tag, isSelected: selectedTags.contains(tag)) {
                            toggleTag(tag)
                        }
                    }
                }
            }
        }
        .alert("Add Tag", isPresented: $showAddTagAlert) {
            TextField("Tag name", text: $newTagName)

            Button("Cancel", role: .cancel) {
                newTagName = ""
            }

            Button("Add") {
                addCustomTag()
            }
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
    }

    private var starSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                SectionHeader(title: "The STAR Method")

                Image(systemName: "info.circle")
                    .foregroundStyle(Color.ink400)
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
                Button("Select a job application…") {
                    selectedJob = nil
                }
            } label: {
                HStack {
                    Text(selectedJob ?? "Select a job application…")
                        .foregroundStyle(Color.ink500)

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
        }
    }

    private func toggleTag(_ tag: String) {
        if selectedTags.contains(tag) {
            selectedTags.remove(tag)
        } else {
            selectedTags.insert(tag)
        }
    }

    private func addCustomTag() {
        let trimmed = newTagName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        guard !availableTags.contains(trimmed) else {
            newTagName = ""
            return
        }
        customTags.append(trimmed)
        selectedTags.insert(trimmed)
        newTagName = ""
    }

    private func handleScanTapped() {
        guard !isProcessingScan else { return }

        if !purchaseManager.isPro {
            activeSheet = .paywall
            return
        }

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
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let tagList = Array(selectedTags).sorted()
        let resolvedCategory = tagList.first ?? (story?.category ?? "General")

        if let story {
            story.title = trimmedTitle
            story.category = resolvedCategory
            story.tags = tagList
            story.situation = situation
            story.task = task
            story.action = action
            story.result = result
            story.notes = mergedNotes()
            story.lastUpdated = Date()
        } else {
            let newStory = Story(title: trimmedTitle, category: resolvedCategory, tags: tagList)
            newStory.situation = situation
            newStory.task = task
            newStory.action = action
            newStory.result = result
            newStory.notes = mergedNotes()
            newStory.lastUpdated = Date()
            modelContext.insert(newStory)
        }

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

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Circle()
                    .fill(Color.sage500)
                    .frame(width: 24, height: 24)
                    .overlay(
                        Text(symbol)
                            .font(.caption.bold())
                            .foregroundStyle(.white)
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

                if text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Text(placeholder)
                        .font(.subheadline)
                        .foregroundStyle(Color.ink400)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 18)
                }
            }
        }
    }
}
