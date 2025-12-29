import SwiftUI
import SwiftData

struct AddQuestionView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var purchaseManager: PurchaseManager

    @Query(filter: #Predicate<Question> { $0.isCustom }) private var customQuestions: [Question]

    @State private var text: String = ""
    @State private var category: String = "Behavioral"
    @State private var draftNotes: String = ""
    @State private var selectedTags: [String] = []
    @State private var newTagName: String = ""
    @State private var showAddTagAlert = false
    @State private var showTagActions = false
    @State private var showDiscardConfirmation = false
    @State private var showPaywall = false
    @State private var gateMessage: String?

    private let freeCustomQuestionLimit = 10
    private let defaultCategory = "Behavioral"
    private let categories = ["Behavioral", "Technical", "Leadership"]

    private var proGate: ProGatekeeper {
        ProGatekeeper(isPro: { purchaseManager.isPro }, presentPaywall: { showPaywall = true })
    }

    private var canSave: Bool {
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var hasUnsavedChanges: Bool {
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedNotes = draftNotes.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmedText.isEmpty
            || !trimmedNotes.isEmpty
            || !selectedTags.isEmpty
            || category != defaultCategory
    }

    private var selectedTagsSorted: [String] {
        StoryStore.sortedTags(selectedTags)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                topBar

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 24) {
                        questionSection
                        categorySection
                        draftNotesSection
                        proTipSection

                        if !purchaseManager.isPro {
                            Text(gateMessage ?? ProGate.unlimitedCustomQuestions.inlineMessage)
                                .font(.footnote)
                                .foregroundStyle(Color.ink500)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    .padding(.bottom, 32)
                }
            }
            .background(Color.cream50)
            .navigationBarHidden(true)
            .interactiveDismissDisabled(hasUnsavedChanges)
            .alert("Discard changes?", isPresented: $showDiscardConfirmation) {
                Button("Discard", role: .destructive) { dismiss() }
                Button("Keep Editing", role: .cancel) { }
            } message: {
                Text("You have unsaved changes. Are you sure you want to discard them?")
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView()
                    .environmentObject(purchaseManager)
            }
            .alert("Add tag", isPresented: $showAddTagAlert) {
                TextField("Tag name", text: $newTagName)
                Button("Add") { addTag() }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Add a tag to help you find this question later.")
            }
            .confirmationDialog("Edit Tags", isPresented: $showTagActions, titleVisibility: .visible) {
                Button("Add Tag") { showAddTagAlert = true }
                if !selectedTags.isEmpty {
                    Button("Clear Tags", role: .destructive) { selectedTags.removeAll() }
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Manage the tags for this question.")
            }
        }
        .tapToDismissKeyboard()
    }

    private var topBar: some View {
        ZStack {
            Text("New Question")
                .font(.headline)
                .foregroundStyle(Color.ink900)

            HStack {
                Button(action: handleClose) {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Color.ink500)
                        .frame(width: 32, height: 32)
                        .background(
                            Circle()
                                .fill(Color.surfaceWhite)
                        )
                        .overlay(
                            Circle()
                                .stroke(Color.ink200, lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Close")

                Spacer()

                Button("Save") { saveAndDismiss() }
                    .font(.headline)
                    .foregroundStyle(canSave ? Color.sage500 : Color.ink300)
                    .disabled(!canSave)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(Color.cream50)
    }

    private var questionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionLabel("THE QUESTION")

            CardContainer(backgroundColor: Color.surfaceWhite, cornerRadius: 18, showShadow: false) {
                ZStack(alignment: .topLeading) {
                    if text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        Text("e.g. Tell me about a time you had to manage conflicting priorities...")
                            .font(.subheadline)
                            .foregroundStyle(Color.ink400)
                            .padding(.top, 8)
                    }

                    TextEditor(text: $text)
                        .frame(minHeight: 140)
                        .scrollContentBackground(.hidden)
                        .foregroundStyle(Color.ink900)
                }
            }
        }
    }

    private var categorySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                sectionLabel("CATEGORY")
                Spacer()
                Button("Edit Tags") { showTagActions = true }
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.sage500)
                    .buttonStyle(.plain)
            }

            HStack(spacing: 10) {
                ForEach(categories, id: \.self) { option in
                    CategoryChip(title: option, isSelected: option == category) {
                        category = option
                    }
                }
            }

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 90), spacing: 8)], alignment: .leading, spacing: 8) {
                ForEach(selectedTagsSorted, id: \.self) { tag in
                    TagPill(title: tag, showsRemove: true) {
                        selectedTags.removeAll { $0 == tag }
                    }
                }

                Button {
                    showAddTagAlert = true
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "plus")
                        Text("Add")
                    }
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.ink600)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(
                        Capsule()
                            .fill(Color.ink100)
                    )
                    .overlay(
                        Capsule()
                            .stroke(Color.ink200, lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var draftNotesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                sectionLabel("DRAFT ANSWER / KEY NOTES")

                Text("Optional")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(Color.ink500)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(Color.ink100)
                    )
            }

            CardContainer(backgroundColor: Color.surfaceWhite, cornerRadius: 18, showShadow: false) {
                ZStack(alignment: .topLeading) {
                    if draftNotes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        Text("Capture STAR bullets or key notes you want to reference when drafting your answer.")
                            .font(.subheadline)
                            .foregroundStyle(Color.ink400)
                            .padding(.top, 8)
                    }

                    TextEditor(text: $draftNotes)
                        .frame(minHeight: 140)
                        .scrollContentBackground(.hidden)
                        .foregroundStyle(Color.ink900)
                }
            }
        }
    }

    private var proTipSection: some View {
        CardContainer(backgroundColor: Color.sage100.opacity(0.25), cornerRadius: 18, showShadow: false, padding: 14) {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "leaf.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color.sage500)

                VStack(alignment: .leading, spacing: 6) {
                    Text("Pro Tip")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.sage500)

                    Text("Keep your notes short and action-focused. You can always expand into a full STAR story later.")
                        .font(.subheadline)
                        .foregroundStyle(Color.ink600)
                }
            }
        }
    }

    private func sectionLabel(_ title: String) -> some View {
        Text(title)
            .font(.caption.weight(.semibold))
            .foregroundStyle(Color.ink500)
            .tracking(1)
    }

    private func handleClose() {
        if hasUnsavedChanges {
            showDiscardConfirmation = true
        } else {
            dismiss()
        }
    }

    private func addTag() {
        let trimmed = newTagName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let normalized = StoryStore.normalizeTags(selectedTags + [trimmed])
        selectedTags = normalized
        newTagName = ""
    }

    private func saveAndDismiss() {
        if !purchaseManager.isPro, customQuestions.count >= freeCustomQuestionLimit {
            proGate.requirePro(.unlimitedCustomQuestions, onAllowed: {}, onBlocked: {
                gateMessage = ProGate.unlimitedCustomQuestions.inlineMessage
            })
            return
        }

        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else { return }

        let trimmedNotes = draftNotes.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedTags = StoryStore.sortedTags(selectedTags)

        let newQuestion = Question(
            text: trimmedText,
            category: category,
            isCustom: true,
            tags: normalizedTags,
            draftNotes: trimmedNotes
        )

        // Optional: keep timestamps consistent (your init already sets them)
        newQuestion.updatedAt = Date()

        modelContext.insert(newQuestion)
        dismiss()
    }
}

private struct CategoryChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.caption.weight(.semibold))
                }
                Text(title)
                    .font(.caption.weight(.semibold))
            }
            .foregroundStyle(isSelected ? Color.surfaceWhite : Color.ink600)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(isSelected ? Color.sage500 : Color.surfaceWhite)
            )
            .overlay(
                Capsule()
                    .stroke(isSelected ? Color.sage500 : Color.ink200, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

private struct TagPill: View {
    let title: String
    var showsRemove: Bool = false
    var action: (() -> Void)? = nil

    private var foregroundColor: Color {
        TagColorResolver.color(forTag: title)
    }

    private var backgroundColor: Color {
        TagColorResolver.background(forTag: title)
    }

    var body: some View {
        Group {
            if let action {
                Button(action: action) { pillBody }
                    .buttonStyle(.plain)
            } else {
                pillBody
            }
        }
    }

    private var pillBody: some View {
        HStack(spacing: 6) {
            Text(title)
                .font(.caption.weight(.semibold))

            if showsRemove {
                Image(systemName: "xmark")
                    .font(.caption2.weight(.semibold))
            }
        }
        .foregroundStyle(foregroundColor)
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .background(
            Capsule()
                .fill(backgroundColor)
        )
        .overlay(
            Capsule()
                .stroke(foregroundColor.opacity(0.25), lineWidth: 1)
        )
    }
}
