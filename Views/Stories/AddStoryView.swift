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
                        ProGate(isPro: purchaseManager.isPro, isPaywallPresented: $showPaywall)
                            .requirePro {
                                showScanner = true
                            }
                    }
                }
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView()
                    .environmentObject(purchaseManager)
            }
            .sheet(isPresented: $showScanner) {
                DocumentScannerView(onSuccess: { images in
                    showScanner = false
                    OCRService.recognizeText(in: images) { result in
                        if case .success(let text) = result {
                            let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
                            guard !trimmed.isEmpty else { return }
                            scannedText = text
                            showInsertPicker = true
                        }
                    }
                }, onCancel: {
                    showScanner = false
                }, onError: { _ in
                    showScanner = false
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
