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

    // Scan flow
    @State private var isProcessingScan = false
    @State private var scannedText = ""

    // Single-sheet state (prevents sheet stacking / jank)
    @State private var activeSheet: ActiveSheet?

    // Alerts (empty OCR, simulator message, errors)
    @State private var activeAlert: ScanAlert?

    let categories = ["General", "Leadership", "Conflict", "Challenge", "Success", "Failure"]

    enum ActiveSheet: Identifiable {
        case paywall
        case scanner
        case insertPicker

        var id: String {
            switch self {
            case .paywall: return "paywall"
            case .scanner: return "scanner"
            case .insertPicker: return "insertPicker"
            }
        }
    }

    struct ScanAlert: Identifiable {
        let id = UUID()
        let title: String
        let message: String
    }

    var body: some View {
        NavigationStack {
            Form {
                // ✅ Option A: Discoverable Scan row at the top of the form
                Section {
                    Button {
                        handleScanTapped()
                    } label: {
                        HStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(Color.sage500.opacity(0.15))
                                    .frame(width: 34, height: 34)

                                Image(systemName: "doc.text.viewfinder")
                                    .foregroundStyle(Color.sage500)
                                    .font(.system(size: 16, weight: .semibold))
                            }

                            VStack(alignment: .leading, spacing: 2) {
                                Text("Scan handwritten notes")
                                    .foregroundStyle(Color.ink900)
                                    .font(.body)
                                    .fontWeight(.semibold)

                                Text(purchaseManager.isPro ? "Auto-fill Situation, Task, Action, Result" : "Pro feature • Tap to unlock")
                                    .foregroundStyle(Color.ink600)
                                    .font(.caption)
                            }

                            Spacer()

                            if isProcessingScan {
                                ProgressView()
                            } else {
                                Image(systemName: "chevron.right")
                                    .foregroundStyle(Color.ink400)
                            }
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .disabled(isProcessingScan)
                }

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
                        .disabled(isProcessingScan)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveStory() }
                        .disabled(isProcessingScan || title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
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

                case .insertPicker:
                    ScanInsertPickerView(
                        scannedText: scannedText,
                        situation: $situation,
                        task: $task,
                        action: $action,
                        result: $result
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
                // ✅ OCRService now returns already-cleaned, non-garbage text (or throws noTextFound)
                scannedText = text
                activeSheet = .insertPicker

            case .failure(let error):
                // ✅ Handle the dedicated “no text found” case with a friendly message
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

