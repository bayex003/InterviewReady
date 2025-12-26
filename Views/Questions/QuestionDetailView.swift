// Testing Checklist:
// - Manual: open question, type something, go back → attempt added
// - Manual: open question, do nothing, go back → no attempt
// - Drill: stop recording on a question → drill attempt added
// - Attempt history: Pro user sees list; free user sees locked message + paywall opens
// - App compiles and runs

import SwiftUI
import SwiftData

struct QuestionDetailView: View {
    @Bindable var question: Question

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var purchaseManager: PurchaseManager

    @Query(sort: \PracticeAttempt.createdAt, order: .reverse) private var allAttempts: [PracticeAttempt]

    @State private var showTip = false
    @State private var showExample = false
    @State private var showHistory = false
    @State private var showPaywall = false
    @State private var didEditThisSession = false
    @State private var showDeleteConfirmation = false

    private let categories = ["General", "Basics", "Behavioral", "Technical", "Strengths", "Weaknesses"]

    private var canEditCustomQuestion: Bool {
        question.isCustom && purchaseManager.isPro
    }

    private var questionTextBinding: Binding<String> {
        Binding(
            get: { question.text },
            set: { newValue in
                question.text = newValue
                question.updatedAt = Date()
            }
        )
    }

    private var tipBinding: Binding<String> {
        Binding(
            get: { question.tip ?? "" },
            set: { newValue in
                question.tip = newValue
                question.updatedAt = Date()
            }
        )
    }

    private var exampleAnswerBinding: Binding<String> {
        Binding(
            get: { question.exampleAnswer ?? "" },
            set: { newValue in
                question.exampleAnswer = newValue
                question.updatedAt = Date()
            }
        )
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {

                // Question Header Card
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "bubble.left.and.bubble.right.fill")
                            .foregroundStyle(Color.sage500)

                        if canEditCustomQuestion {
                            Menu {
                                ForEach(categories, id: \.self) { category in
                                    Button(category) {
                                        question.category = category
                                        question.updatedAt = Date()
                                    }
                                }
                            } label: {
                                HStack(spacing: 6) {
                                    Text(question.category.uppercased())
                                        .font(.caption)
                                        .fontWeight(.bold)
                                        .foregroundStyle(Color.sage500)
                                    Image(systemName: "chevron.down")
                                        .font(.caption2)
                                        .foregroundStyle(Color.sage500)
                                }
                            }
                        } else {
                            Text(question.category.uppercased())
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundStyle(Color.sage500)
                        }

                        Spacer()
                    }

                    if canEditCustomQuestion {
                        TextEditor(text: questionTextBinding)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundStyle(Color.ink900)
                            .scrollContentBackground(.hidden)
                            .frame(minHeight: 90)
                    } else {
                        Text(question.text)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundStyle(Color.ink900)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding(20)
                .background(Color.surfaceWhite)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)

                // Tip
                DisclosureCard(
                    title: "Tip",
                    systemImage: "lightbulb",
                    isExpanded: $showTip
                ) {
                    if canEditCustomQuestion {
                        TextEditor(text: tipBinding)
                            .font(.body)
                            .foregroundStyle(Color.ink900)
                            .scrollContentBackground(.hidden)
                            .frame(minHeight: 120)
                    } else {
                        let tipText = (question.tip ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
                        if tipText.isEmpty {
                            Text("No tip available yet.")
                                .font(.body)
                                .foregroundStyle(Color.ink600)
                        } else {
                            Text(tipText)
                                .font(.body)
                                .foregroundStyle(Color.ink900)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }

                // Example answer
                DisclosureCard(
                    title: "Example answer",
                    systemImage: "doc.text",
                    isExpanded: $showExample
                ) {
                    if canEditCustomQuestion {
                        TextEditor(text: exampleAnswerBinding)
                            .font(.body)
                            .foregroundStyle(Color.ink900)
                            .scrollContentBackground(.hidden)
                            .frame(minHeight: 140)
                    } else {
                        let exampleText = (question.exampleAnswer ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
                        if exampleText.isEmpty {
                            Text("No example answer available yet.")
                                .font(.body)
                                .foregroundStyle(Color.ink600)
                        } else {
                            Text(exampleText)
                                .font(.body)
                                .foregroundStyle(Color.ink900)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }

                // Your Answer input
                VStack(alignment: .leading, spacing: 8) {
                    Text("YOUR ANSWER")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundStyle(Color.ink600)
                        .padding(.leading, 4)

                    ZStack(alignment: .topLeading) {
                        if question.answerText.isEmpty {
                            Text("Tap here to type your full answer…")
                                .font(.body)
                                .foregroundStyle(Color.ink400)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 16)
                                .allowsHitTesting(false)
                        }

                        TextEditor(text: $question.answerText)
                            .font(.body)
                            .foregroundStyle(Color.ink900)
                            .scrollContentBackground(.hidden)
                            .padding(12)
                            .frame(minHeight: 400)
                    }
                    .background(Color.surfaceWhite)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(Color.ink200, lineWidth: 1)
                    )
                }

                DisclosureCard(
                    title: "Attempt History",
                    systemImage: "clock.arrow.circlepath",
                    isExpanded: $showHistory
                ) {
                    let attemptsForQuestion = allAttempts.filter {
                        ($0.questionId == question.id) || ($0.questionTextSnapshot == question.text)
                    }
                    let recentAttempts = attemptsForQuestion.prefix(10)

                    if purchaseManager.isPro {
                        if recentAttempts.isEmpty {
                            Text("No attempts yet.")
                                .font(.body)
                                .foregroundStyle(Color.ink600)
                        } else {
                            ForEach(recentAttempts, id: \.id) { attempt in
                                HStack {
                                    Text(attempt.createdAt, style: .date)
                                        .font(.body)
                                        .foregroundStyle(Color.ink900)

                                    Spacer()

                                    Text(attempt.source == "manual" ? "Manual" : "Drill")
                                        .font(.subheadline)
                                        .foregroundStyle(Color.ink600)
                                }
                            }
                        }
                    } else {
                        Text("Pro feature. Upgrade to view your attempt history.")
                            .font(.body)
                            .foregroundStyle(Color.ink600)

                        Button {
                            showPaywall = true
                        } label: {
                            Text("Upgrade to Pro")
                                .fontWeight(.bold)
                                .padding(.vertical, 10)
                                .frame(maxWidth: .infinity)
                                .background(Color.clear)
                                .foregroundStyle(Color.ink900)
                                .overlay(Capsule().strokeBorder(Color.ink200, lineWidth: 1))
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }

                if canEditCustomQuestion {
                    Button(role: .destructive) {
                        showDeleteConfirmation = true
                    } label: {
                        Text("Delete Question")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .overlay(
                                Capsule()
                                    .strokeBorder(Color.red.opacity(0.6), lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                }

                Spacer(minLength: 60)
            }
            .padding()
        }
        .background(Color.cream50)
        .tapToDismissKeyboard()
        .hidesFloatingTabBar()
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: question.answerText) { _, _ in
            didEditThisSession = true
        }
        .onDisappear {
            if !question.answerText.isEmpty, didEditThisSession {
                question.dateAnswered = Date()
                question.isAnswered = true

                let attempt = PracticeAttempt(
                    source: "manual",
                    questionTextSnapshot: question.text,
                    questionId: question.id
                )
                modelContext.insert(attempt)
                try? modelContext.save()
            } else if question.answerText.isEmpty {
                question.isAnswered = false
            }
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView()
                .environmentObject(purchaseManager)
        }
        .alert("Delete this question?", isPresented: $showDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                deleteQuestion()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will remove your custom question permanently.")
        }
    }

    private func deleteQuestion() {
        modelContext.delete(question)
        try? modelContext.save()
        dismiss()
    }
}

private struct DisclosureCard<Content: View>: View {
    let title: String
    let systemImage: String
    @Binding var isExpanded: Bool
    @ViewBuilder var content: () -> Content

    // A smoother, less "jumpy" transition for variable-height content
    private var contentTransition: AnyTransition {
        .asymmetric(
            insertion: .opacity.combined(with: .scale(scale: 0.98, anchor: .top)),
            removal: .opacity
        )
    }

    var body: some View {
        VStack(spacing: 0) {
            Button {
                // Let the .animation(value:) drive the entire transition smoothly
                isExpanded.toggle()
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: systemImage)
                        .foregroundStyle(Color.ink600)

                    Text(title)
                        .font(.headline)
                        .foregroundStyle(Color.ink900)

                    Spacer()

                    Image(systemName: "chevron.down")
                        .foregroundStyle(Color.ink400)
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                }
                .padding(16)
                .contentShape(Rectangle()) // bigger tap target = feels smoother
            }
            .buttonStyle(.plain)

            if isExpanded {
                Divider().opacity(0.6)

                VStack(alignment: .leading, spacing: 10) {
                    content()
                }
                .padding(16)
                .transition(contentTransition)
            }
        }
        .background(Color.surfaceWhite)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
        // ✅ This is the key: animate the whole card’s layout changes
        .animation(.snappy(duration: 0.28), value: isExpanded)
    }
}
