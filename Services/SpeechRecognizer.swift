import Foundation
import Speech
import SwiftUI
import AVFoundation
import Combine

@MainActor
final class SpeechRecognizer: ObservableObject {
    @Published var transcribedText = ""
    @Published var isRecording = false
    @Published var error: String?

    private let recognizer: SFSpeechRecognizer? = SFSpeechRecognizer()
    private let audioEngine = AVAudioEngine()

    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var task: SFSpeechRecognitionTask?

    func startRecording() {
        guard !isRecording else { return }
        error = nil

        guard let recognizer, recognizer.isAvailable else {
            error = "Speech recognition is unavailable right now."
            return
        }

        Task {
            let speechOK = await requestSpeechAuthorization()
            guard speechOK else {
                self.error = "Speech recognition access is required to transcribe your response."
                return
            }

            let micOK = await requestMicrophonePermission()
            guard micOK else {
                self.error = "Microphone access is required to record your response."
                return
            }

            do {
                try self.startAuthorizedRecording(recognizer: recognizer)
            } catch {
                self.error = "Error: \(error.localizedDescription)"
                self.stopRecording()
            }
        }
    }

    // MARK: - Permissions

    private func requestSpeechAuthorization() async -> Bool {
        let status = SFSpeechRecognizer.authorizationStatus()
        switch status {
        case .authorized:
            return true
        case .notDetermined:
            return await withCheckedContinuation { continuation in
                SFSpeechRecognizer.requestAuthorization { newStatus in
                    continuation.resume(returning: newStatus == .authorized)
                }
            }
        default:
            return false
        }
    }

    private func requestMicrophonePermission() async -> Bool {
        // iOS 17+ replacement for requestRecordPermission / recordPermission (removes deprecation warnings)
        if #available(iOS 17.0, *) {
            return await withCheckedContinuation { continuation in
                AVAudioApplication.requestRecordPermission { granted in
                    continuation.resume(returning: granted)
                }
            }
        } else {
            return await withCheckedContinuation { continuation in
                AVAudioSession.sharedInstance().requestRecordPermission { granted in
                    continuation.resume(returning: granted)
                }
            }
        }
    }

    // MARK: - Recording

    private func startAuthorizedRecording(recognizer: SFSpeechRecognizer) throws {
        // Clean up any previous run
        stopRecording()

        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.record, mode: .measurement, options: [.duckOthers])
        try audioSession.setActive(true, options: [.notifyOthersOnDeactivation])

        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        self.request = request

        let inputNode = audioEngine.inputNode
        inputNode.removeTap(onBus: 0)

        let format = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] buffer, _ in
            self?.request?.append(buffer)
        }

        audioEngine.prepare()
        try audioEngine.start()

        isRecording = true
        transcribedText = ""

        task = recognizer.recognitionTask(with: request) { [weak self] result, err in
            guard let self else { return }
            Task { @MainActor in
                if let result {
                    self.transcribedText = result.bestTranscription.formattedString
                }
                if err != nil || (result?.isFinal ?? false) {
                    self.stopRecording()
                }
            }
        }
    }

    func stopRecording() {
        // Safe to call multiple times
        if audioEngine.isRunning {
            audioEngine.stop()
        }
        audioEngine.inputNode.removeTap(onBus: 0)

        request?.endAudio()
        task?.cancel()

        request = nil
        task = nil
        isRecording = false

        // Deactivate session (best-effort)
        try? AVAudioSession.sharedInstance().setActive(false, options: [.notifyOthersOnDeactivation])
    }
}

