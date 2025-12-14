import SwiftUI

private extension Notification.Name {
    static let dictationStopAll = Notification.Name("dictationStopAll")
}

struct DictationButton: View {
    @Binding var text: String
    @StateObject private var speechRecognizer = SpeechRecognizer()

    // Haptic Generator
    private let feedback = UIImpactFeedbackGenerator(style: .medium)

    // Local state to safely append
    @State private var baseTextBeforeDictation: String = ""
    @State private var shouldAppendOnStop: Bool = false

    // Unique ID so we don’t stop ourselves when broadcasting stop
    private let id = UUID()

    var body: some View {
        Button(action: {
            feedback.impactOccurred()

            if speechRecognizer.isRecording {
                speechRecognizer.stopRecording()
            } else {
                // Stop any other DictationButton instances that might be recording
                NotificationCenter.default.post(name: .dictationStopAll, object: id)

                // Snapshot the current text so we can append safely later
                baseTextBeforeDictation = text
                shouldAppendOnStop = true

                speechRecognizer.startRecording()
            }
        }) {
            Image(systemName: speechRecognizer.isRecording ? "stop.circle.fill" : "mic.circle.fill")
                .font(.system(size: 44))
                .foregroundColor(speechRecognizer.isRecording ? .red : Color.sage500)
                .symbolEffect(.bounce, value: speechRecognizer.isRecording)
                .background(Color.white)
                .clipShape(Circle())
                .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 2)
        }
        // If another DictationButton starts recording, stop this one
        .onReceive(NotificationCenter.default.publisher(for: .dictationStopAll)) { note in
            guard let senderId = note.object as? UUID else { return }
            if senderId != id, speechRecognizer.isRecording {
                speechRecognizer.stopRecording()
            }
        }
        // When recording ends, append the final transcript once
        .onChange(of: speechRecognizer.isRecording) { _, isRecording in
            guard isRecording == false, shouldAppendOnStop else { return }

            let transcript = speechRecognizer.transcribedText.trimmingCharacters(in: .whitespacesAndNewlines)
            let base = baseTextBeforeDictation

            if !transcript.isEmpty {
                text = appendTranscript(transcript, to: base)
            } else {
                text = base
            }

            shouldAppendOnStop = false
        }
    }

    private func appendTranscript(_ transcript: String, to base: String) -> String {
        let trimmedBase = base.trimmingCharacters(in: .whitespacesAndNewlines)

        // If the field was empty, just set transcript
        if trimmedBase.isEmpty {
            return transcript
        }

        // If base already ends with whitespace/newline, avoid double spacing
        if base.last?.isWhitespace == true {
            return base + transcript
        }

        // Default: add a single space between
        return base + " " + transcript
    }
}
