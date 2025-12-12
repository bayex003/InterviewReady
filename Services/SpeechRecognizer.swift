import Foundation
import Speech
import AVFoundation
import SwiftUI
import Combine

// A view model that manages the speech recognition process
@MainActor
class SpeechRecognizer: ObservableObject {
    @Published var transcribedText: String = ""
    @Published var isRecording: Bool = false
    @Published var errorMessage: String? = nil
    
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))!
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    
    init() {
        requestAuthorization()
    }
    
    private func requestAuthorization() {
        SFSpeechRecognizer.requestAuthorization { authStatus in
            // In a real app, handle different auth states (denied, restricted, etc.)
            // For V1 scaffolding, we assume they say yes.
            print("Speech auth status: \(authStatus)")
        }
    }
    
    func startRecording() {
        if isRecording { stopRecording(); return }
        
        // Clear previous state
        transcribedText = ""
        errorMessage = nil
        
        // Configure audio session
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            self.errorMessage = "Failed to setup audio session"
            return
        }
        
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else { return }
        recognitionRequest.shouldReportPartialResults = true
        
        // Configure microphone input
        let inputNode = audioEngine.inputNode
        
        // Start recognition task
        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { [weak self] result, err in
            guard let self = self else { return }
            
            if let result = result {
                self.transcribedText = result.bestTranscription.formattedString
                if result.isFinal {
                    self.stopRecording()
                }
            }
            
            if let err = err {
                self.errorMessage = err.localizedDescription
                self.stopRecording()
            }
        }
        
        // Start audio engine
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer, when) in
            recognitionRequest.append(buffer)
        }
        
        do {
            try audioEngine.start()
            isRecording = true
        } catch {
            self.errorMessage = "Could not start audio engine"
            stopRecording()
        }
    }
    
    func stopRecording() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        
        // Important: Deactivate session to return audio to other apps
        try? AVAudioSession.sharedInstance().setActive(false)
        
        recognitionRequest = nil
        recognitionTask = nil
        isRecording = false
    }
}
