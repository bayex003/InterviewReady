import SwiftUI
import SwiftData

struct StartDrillSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var availableCount: Int = 0
    @State private var drillQuestions: [QuestionBankItem] = []
    @State private var showDrill = false
    @State private var showQuestionSelection = false
    @State private var showQuestionBank = false

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                PrimaryCTAButton("Start now (3 random)") {
                    startRandomDrill()
                }
                .opacity(availableCount < 3 ? 0.5 : 1)
                .disabled(availableCount < 3)

                secondaryButton(title: "Choose questions") {
                    showQuestionSelection = true
                }

                helperSection

                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .background(Color.cream50.ignoresSafeArea())
            .navigationTitle("Start a drill")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
            .onAppear(perform: refreshAvailableCount)
            .navigationDestination(isPresented: $showDrill) {
                PracticeSessionView(questions: drillQuestions)
            }
            .navigationDestination(isPresented: $showQuestionSelection) {
                QuestionsListView(initialSelectionMode: true, showsSelectionToggle: false)
            }
            .navigationDestination(isPresented: $showQuestionBank) {
                QuestionsListView()
            }
        }
    }

    private var helperSection: some View {
        Group {
            if availableCount < 3 {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Add a few questions to start a drill.")
                        .font(.footnote)
                        .foregroundStyle(Color.ink500)

                    secondaryButton(title: "Go to Question Bank") {
                        showQuestionBank = true
                    }
                }
            } else {
                Text("You can speak or type your answers.")
                    .font(.footnote)
                    .foregroundStyle(Color.ink500)
            }
        }
    }

    private func secondaryButton(title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Text(title)
                    .fontWeight(.semibold)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.headline)
            }
            .foregroundStyle(Color.ink700)
            .padding(.vertical, 14)
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity)
            .background(Color.surfaceWhite)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Color.ink200, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private func refreshAvailableCount() {
        availableCount = fetchDrillCandidates().count
    }

    private func startRandomDrill() {
        let candidates = fetchDrillCandidates()
        guard candidates.count >= 3 else {
            availableCount = candidates.count
            return
        }

        drillQuestions = Array(candidates.shuffled().prefix(3)).map { QuestionBankItem($0) }
        AnalyticsEventLogger.shared.log(.drillStartedRandom)
        showDrill = true
    }

    private func fetchDrillCandidates() -> [Question] {
        let descriptor = FetchDescriptor<Question>()
        do {
            return try modelContext.fetch(descriptor).filter {
                !$0.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            }
        } catch {
            return []
        }
    }
}
