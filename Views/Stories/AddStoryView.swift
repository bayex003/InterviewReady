// Manual test checklist:
// - Scan -> OCR -> insert -> field updates once only
// - Tapping Insert repeatedly doesn’t duplicate
// - Empty/garbage OCR output disables Insert
// - While processing, Scan Notes can’t be triggered again
// - Simulator shows friendly message, no crash
import SwiftUI
import SwiftData

struct AddStoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var purchaseManager: PurchaseManager

    // Form Inputs
    @State private var title = ""
    @State private var category = "General"
    @State private var situation = ""
    @State private var task = ""
    @State private var action = ""
    @State private var result = ""
    @State private var showPaywall = false
    @State private var showScanner = false
    @State private var showInsertPicker = false
    @State private var scannedText = ""
    @State private var isProcessingScan = false

    let categories = ["General", "Leadership", "Conflict", "Challenge", "Success", "Failure"]

    var body: some View {
        NavigationStack {
            Form {
                Section("Career Moment Details") {
                    TextField("Title (e.g. Database Migration)", text: $title)
                    Picker("Category", selection: $category) {
                        ForEach(categories, id: \.self) { cat in
                            Text(cat).tag(cat)
                        }
                    }
                }

                starInputSection(
                    header: "Situation",
                    text: $situation,
                    placeholder: "Where/when was this? What was happening?"
                )

                starInputSection(
                    header: "Task",
                    text: $task,
                    placeholder: "What were you responsible for? What was the goal/challenge?"
                )

                starInputSection(
                    header: "Action",
                    text: $action,
                    placeholder: "What did YOU do? Key steps, decisions, tools."
                )

                starInputSection(
                    header: "Result",
                    text: $result,
                    placeholder: "What changed? Add impact/metrics if possible (time, quality, customer)."
                )
            }
            .navigationTitle("New Career Moment")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveStory() }
                        .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Scan Notes") {
                        if purchaseManager.isPro {
                            showScanner = true
                        } else {
                            showPaywall = true
                        }
                    }
                    .disabled(isProcessingScan)
                }
            }
            .overlay {
                if isProcessingScan {
                    VStack(spacing: 8) {
                        ProgressView()
                        Text("Processing scan…")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(12)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView()
                    .environmentObject(purchaseManager)
            }
            .sheet(isPresented: $showScanner) {
                DocumentScannerView(onSuccess: { images in
                    showScanner = false
                    isProcessingScan = true
                    OCRService.recognizeText(in: images) { result in
                        isProcessingScan = false
                        if case .success(let text) = result {
                            let cleanedText = OCRService.cleanText(text)
                            guard !cleanedText.isEmpty else { return }
                            scannedText = cleanedText
                            showInsertPicker = true
                        }
                    }
                }, onCancel: {
                    showScanner = false
                    isProcessingScan = false
                }, onError: { _ in
                    showScanner = false
                    isProcessingScan = false
                })
            }
            .sheet(isPresented: $showInsertPicker) {
                ScanInsertPickerView(
                    scannedText: scannedText,
                    situation: $situation,
                    task: $task,
                    action: $action,
                    result: $result
                )
            }
        }
    }

    private func saveStory() {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)

        let newStory = Story(title: trimmedTitle, category: category)
        newStory.situation = situation
        newStory.task = task
        newStory.action = action
        newStory.result = result

        modelContext.insert(newStory)
        dismiss()
    }

    @ViewBuilder
    private func starInputSection(header: String, text: Binding<String>, placeholder: String) -> some View {
        Section(header: Text(header)) {
            TextEditor(text: text)
                .frame(minHeight: 100)

            if text.wrappedValue.isEmpty {
                Text(placeholder)
                    .font(.caption)
                    .foregroundStyle(.gray)
            }
        }
    }
}

