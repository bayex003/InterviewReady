import SwiftUI
import SwiftData

struct AddQuestionView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var purchaseManager: PurchaseManager

    @Query(filter: #Predicate<Question> { $0.isCustom }) private var customQuestions: [Question]

    @State private var text: String = ""
    @State private var category: String = "General"
    @State private var tip: String = ""
    @State private var exampleAnswer: String = ""
    @State private var showPaywall = false
    @State private var gateMessage: String?

    private let freeCustomQuestionLimit = 10

    private var proGate: ProGatekeeper {
        ProGatekeeper(isPro: { purchaseManager.isPro }, presentPaywall: { showPaywall = true })
    }

    // Keep categories flexible; you can edit this list anytime
    private let categories = [
        "General", "Basics", "Behavioural", "Technical",
        "Leadership", "Conflict", "Challenge", "Success", "Failure"
    ]

    var body: some View {
        NavigationStack {
            Form {
                Section("Question") {
                    TextEditor(text: $text)
                        .frame(minHeight: 120)

                    Picker("Category", selection: $category) {
                        ForEach(categories, id: \.self) { c in
                            Text(c).tag(c)
                        }
                    }
                }

                Section("Tip (optional)") {
                    TextEditor(text: $tip)
                        .frame(minHeight: 100)
                }

                Section("Example answer (optional)") {
                    TextEditor(text: $exampleAnswer)
                        .frame(minHeight: 140)
                }

                if !purchaseManager.isPro {
                    Section {
                        if let gateMessage {
                            Text(gateMessage)
                                .font(.footnote)
                                .foregroundStyle(Color.ink500)
                        } else {
                            Text(ProGate.unlimitedCustomQuestions.inlineMessage)
                                .font(.footnote)
                                .foregroundStyle(Color.ink500)
                        }
                    }
                }
            }
            .navigationTitle("New Question")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveAndDismiss() }
                        .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView()
                    .environmentObject(purchaseManager)
            }
        }
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

        let trimmedTip = tip.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedExample = exampleAnswer.trimmingCharacters(in: .whitespacesAndNewlines)

        let newQuestion = Question(
            text: trimmedText,
            category: category,
            isCustom: true,
            tip: trimmedTip.isEmpty ? nil : trimmedTip,
            exampleAnswer: trimmedExample.isEmpty ? nil : trimmedExample
        )

        // Optional: keep timestamps consistent (your init already sets them)
        newQuestion.updatedAt = Date()

        modelContext.insert(newQuestion)
        dismiss()
    }
}
