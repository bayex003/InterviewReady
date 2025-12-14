import Foundation
import Speech
import SwiftUI
import AVFoundation
import Combine

class SpeechRecognizer: ObservableObject {
    @Published var transcribedText = ""
    @Published var isRecording = false
    @Published var error: String?
    
    private var audioEngine: AVAudioEngine?
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var task: SFSpeechRecognitionTask?
    private let recognizer: SFSpeechRecognizer?
    
    init() {
        recognizer = SFSpeechRecognizer()
        Task(priority: .background) {
            await verifyPermissions()
        }
    }
    
    @MainActor
    private func verifyPermissions() {
        SFSpeechRecognizer.requestAuthorization { _ in }
    }
    
    func startRecording() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self, let recognizer = self.recognizer, recognizer.isAvailable else { return }
            
            do {
                let audioSession = AVAudioSession.sharedInstance()
                try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
                try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
                
                let audioEngine = AVAudioEngine()
                let request = SFSpeechAudioBufferRecognitionRequest()
                request.shouldReportPartialResults = true
                
                let inputNode = audioEngine.inputNode
                let recordingFormat = inputNode.outputFormat(forBus: 0)
                inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
                    request.append(buffer)
                }
                
                audioEngine.prepare()
                try audioEngine.start()
                
                DispatchQueue.main.async {
                    self.audioEngine = audioEngine
                    self.request = request
                    self.isRecording = true
                    self.transcribedText = ""
                    
                    self.task = recognizer.recognitionTask(with: request) { result, error in
                        if let result = result {
                            self.transcribedText = result.bestTranscription.formattedString
                        }
                        if error != nil || (result?.isFinal ?? false) {
                            self.stopRecording()
                        }
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    self.error = "Error: \(error.localizedDescription)"
                    self.stopRecording()
                }
            }
        }
    }
    
    func stopRecording() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            self.audioEngine?.stop()
            self.audioEngine?.inputNode.removeTap(onBus: 0)
            self.request?.endAudio()
            self.task?.cancel()
            try? AVAudioSession.sharedInstance().setActive(false)
            
            DispatchQueue.main.async {
                self.audioEngine = nil
                self.request = nil
                self.task = nil
                self.isRecording = false
            }
        }
    }
}
