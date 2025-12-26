// Manual test checklist:
// - Scan -> OCR -> insert -> field updates once only
// - Tapping Insert repeatedly doesn’t duplicate
// - Empty/garbage OCR output disables Insert
// - While processing, Scan Notes can’t be triggered again
// - Simulator shows friendly message, no crash
import SwiftUI

struct StoryDetailView: View {
    @Bindable var story: Story
    @EnvironmentObject private var purchaseManager: PurchaseManager

    @State private var showPaywall = false
    @State private var showScanner = false
    @State private var showInsertPicker = false
    @State private var scannedText = ""
    @State private var isProcessingScan = false

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
                    ProGate(isPro: { purchaseManager.isPro }, isPaywallPresented: $showPaywall)
                        .requirePro {
                            showScanner = true
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

