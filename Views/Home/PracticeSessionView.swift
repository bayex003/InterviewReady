import SwiftUI

struct PracticeSessionView: View {
    let questions: [QuestionBankItem]

    @Environment(\.dismiss) private var dismiss
    @State private var currentIndex = 0
    @State private var inputMode: InputMode = .speak
    @State private var isRecording = false
    @State private var responseText = ""
    @State private var minutes = 1
    @State private var seconds = 45

    private var currentQuestion: QuestionBankItem {
        questions.indices.contains(currentIndex) ? questions[currentIndex] : .placeholder
    }

    private var totalQuestions: Int {
        max(questions.count, 1)
    }

    private var progressValue: Double {
        guard totalQuestions > 0 else { return 0 }
        return Double(min(currentIndex + 1, totalQuestions)) / Double(totalQuestions)
    }

    var body: some View {
        VStack(spacing: 0) {
            topBar
                .padding(.horizontal, 20)
                .padding(.top, 12)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    questionMeta
                    progressBar
                    questionCard
                    inputModeToggle
                    inputArea
                    linkedStoryCard
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 32)
            }

            bottomControls
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
        }
        .background(Color.cream50.ignoresSafeArea())
        .navigationBarBackButtonHidden(true)
    }

    private var topBar: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(Color.ink900)
                    .frame(width: 36, height: 36)
            }
            .buttonStyle(.plain)

            Spacer()

            Text("Practice Session")
                .font(.headline.weight(.semibold))
                .foregroundStyle(Color.ink900)

            Spacer()

            Button {
                dismiss()
            } label: {
                Text("End")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.ink600)
                    .frame(minWidth: 44, minHeight: 36, alignment: .trailing)
            }
            .buttonStyle(.plain)
        }
    }

    private var questionMeta: some View {
        HStack(alignment: .lastTextBaseline) {
            Text("QUESTION \(currentIndex + 1) OF \(totalQuestions)")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.ink600)
                .tracking(1.2)

            Spacer()

            Text(currentQuestion.category.title)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(Color.ink500)
        }
    }

    private var progressBar: some View {
        ProgressView(value: progressValue)
            .progressViewStyle(.linear)
            .tint(Color.sage500)
            .scaleEffect(x: 1, y: 1.4, anchor: .center)
    }

    private var questionCard: some View {
        CardContainer(backgroundColor: Color.surfaceWhite, cornerRadius: 24, showShadow: false) {
            VStack(alignment: .center, spacing: 18) {
                Chip(title: currentQuestion.category.title, isSelected: true)

                Text(currentQuestion.text)
                    .font(.title2.weight(.bold))
                    .foregroundStyle(Color.ink900)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 8)

                HStack(spacing: 16) {
                    TimerBlock(value: String(format: "%02d", minutes), label: "MIN")
                    Text(":")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(Color.ink500)
                    TimerBlock(value: String(format: "%02d", seconds), label: "SEC")
                }
            }
            .frame(maxWidth: .infinity, alignment: .center)
        }
    }

    private var inputModeToggle: some View {
        HStack(spacing: 8) {
            segmentButton(title: "Speak", systemImage: "mic.fill", mode: .speak)
            segmentButton(title: "Write", systemImage: "pencil", mode: .write)
        }
        .padding(6)
        .background(Color.surfaceWhite)
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .stroke(Color.ink200, lineWidth: 1)
        )
    }

    private func segmentButton(title: String, systemImage: String, mode: InputMode) -> some View {
        let isActive = inputMode == mode
        return Button {
            inputMode = mode
        } label: {
            HStack(spacing: 8) {
                Image(systemName: systemImage)
                Text(title)
                    .fontWeight(.semibold)
            }
            .foregroundStyle(isActive ? Color.sage500 : Color.ink600)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(isActive ? Color.sage100 : Color.clear)
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    private var inputArea: some View {
        Group {
            switch inputMode {
            case .speak:
                VStack(spacing: 16) {
                    WaveformView()
                        .frame(height: 60)

                    Text("Listening…")
                        .font(.subheadline)
                        .foregroundStyle(Color.ink500)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            case .write:
                TextEditor(text: $responseText)
                    .frame(minHeight: 140)
                    .padding(12)
                    .background(Color.surfaceWhite)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(Color.ink200, lineWidth: 1)
                    )
            }
        }
    }

    private var linkedStoryCard: some View {
        CardContainer(backgroundColor: Color.surfaceWhite, cornerRadius: 18, showShadow: false) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color.sage100)
                        .frame(width: 40, height: 40)

                    Image(systemName: "link")
                        .foregroundStyle(Color.sage500)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Linked Story")
                        .font(.caption)
                        .foregroundStyle(Color.ink500)

                    Text(linkedStoryTitle)
                        .font(.headline)
                        .foregroundStyle(Color.ink900)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundStyle(Color.ink400)
            }
        }
    }

    private var linkedStoryTitle: String {
        currentQuestion.linkedStories > 0 ? "Project Phoenix Crisis" : "Link a Story"
    }

    private var bottomControls: some View {
        HStack(alignment: .bottom) {
            Button {
                advanceQuestion()
            } label: {
                VStack(spacing: 6) {
                    Circle()
                        .fill(Color.surfaceWhite)
                        .frame(width: 44, height: 44)
                        .overlay(
                            Image(systemName: "forward.fill")
                                .foregroundStyle(Color.ink600)
                                .rotationEffect(.degrees(180))
                        )

                    Text("Skip")
                        .font(.caption)
                        .foregroundStyle(Color.ink600)
                }
            }
            .buttonStyle(.plain)

            Spacer()

            Button {
                isRecording.toggle()
            } label: {
                ZStack {
                    Circle()
                        .fill(isRecording ? Color.sage500 : Color.sage100)
                        .frame(width: 86, height: 86)
                        .shadow(color: Color.sage500.opacity(isRecording ? 0.35 : 0.15), radius: 18)

                    Image(systemName: isRecording ? "stop.fill" : "mic.fill")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(isRecording ? Color.surfaceWhite : Color.sage500)
                }
            }
            .buttonStyle(.plain)

            Spacer()

            Button {
                advanceQuestion()
            } label: {
                VStack(spacing: 6) {
                    Circle()
                        .fill(Color.surfaceWhite)
                        .frame(width: 44, height: 44)
                        .overlay(
                            Image(systemName: "forward.fill")
                                .foregroundStyle(Color.ink600)
                        )

                    Text("Next")
                        .font(.caption)
                        .foregroundStyle(Color.ink600)
                }
            }
            .buttonStyle(.plain)
        }
    }

    private func advanceQuestion() {
        guard currentIndex + 1 < questions.count else { return }
        currentIndex += 1
    }
}

private enum InputMode {
    case speak
    case write
}

private struct TimerBlock: View {
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 6) {
            Text(value)
                .font(.title2.weight(.bold))
                .foregroundStyle(Color.sage500)
                .frame(width: 64, height: 52)
                .background(Color.sage100)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

            Text(label)
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.ink500)
        }
    }
}

private struct WaveformView: View {
    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<7, id: \.self) { index in
                Capsule()
                    .fill(index == 3 ? Color.sage500 : Color.sage500.opacity(0.6))
                    .frame(width: 8, height: index == 3 ? 46 : 30)
            }
        }
    }
}

extension QuestionBankItem {
    static var placeholder: QuestionBankItem {
        QuestionBankItem(
            id: UUID(),
            text: "Describe a situation where you had to handle a difficult client.",
            category: .behavioral,
            linkedStories: 0,
            isAnswered: false,
            iconName: "message.fill",
            tags: []
        )
    }
}
