import SwiftUI

struct StoryDetailView: View {
    @Bindable var story: Story
    @EnvironmentObject private var purchaseManager: PurchaseManager

    @State private var showPaywall = false
    @State private var showScanner = false
    @State private var showInsertPicker = false
    @State private var scannedText = ""

    var body: some View {
        Form {
            Section("Details") {
                TextField("Title", text: $story.title)
                    .font(.headline)

                TextField("Category (e.g. General, Leadership)", text: $story.category)
            }

            // STAR stays, but framed as interview-ready structure
            starSection(title: "Situation", text: $story.situation, placeholder: "Where/when was this? What was happening?")
            starSection(title: "Task", text: $story.task, placeholder: "What were you responsible for? What was the goal/challenge?")
            starSection(title: "Action", text: $story.action, placeholder: "What did YOU do? Key steps, decisions, tools.")
            starSection(title: "Result", text: $story.result, placeholder: "What changed? Add impact/metrics if possible (time, quality, customer).")
        }
        .hidesFloatingTabBar()
        .navigationTitle("Edit Career Moment")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
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
                situation: $story.situation,
                task: $story.task,
                action: $story.action,
                result: $story.result
            )
        }
    }

    private func starSection(title: String, text: Binding<String>, placeholder: String) -> some View {
        Section(header: Text(title).fontWeight(.bold)) {
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
