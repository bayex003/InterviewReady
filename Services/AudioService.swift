import Foundation
import AVFoundation

@Observable
class AudioService: NSObject, AVAudioRecorderDelegate, AVAudioPlayerDelegate {
    var isRecording = false
    var isPlaying = false
    var recordedFileURL: URL?
    
    private var audioRecorder: AVAudioRecorder?
    private var audioPlayer: AVAudioPlayer?
    
    override init() {
        super.init()
        setupSession()
    }
    
    private func setupSession() {
        let session = AVAudioSession.sharedInstance()
        do {
            // "playAndRecord" is required for recording
            // "defaultToSpeaker" ensures it plays back loud, not through the earpiece
            try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetooth])
            try session.setActive(true)
        } catch {
            print("Failed to set up audio session: \(error)")
        }
    }
    
    func startRecording(id: String) {
        // 1. Define the file path
        let fileName = "answer_\(id).m4a"
        let path = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent(fileName)
        
        // 2. Standard High-Quality Settings (44.1kHz is safer than 12kHz)
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100, // Standard sample rate
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        
        do {
            // 3. Create and Start Recorder
            audioRecorder = try AVAudioRecorder(url: path, settings: settings)
            audioRecorder?.delegate = self
            audioRecorder?.record()
            
            isRecording = true
            recordedFileURL = nil // Reset so we don't play an old file
            print("🎙️ Started recording to: \(path)")
        } catch {
            print("Could not start recording: \(error)")
        }
    }
    
    func stopRecording() {
        audioRecorder?.stop()
        isRecording = false
        // We do NOT set recordedFileURL here anymore.
        // We wait for the delegate 'didFinishRecording' to confirm the file is saved.
    }
    
    func playRecording() {
        guard let url = recordedFileURL else {
            print("❌ No file URL found to play.")
            return
        }
        
        // Check if file actually exists and has data
        if let attributes = try? FileManager.default.attributesOfItem(atPath: url.path),
           let fileSize = attributes[.size] as? UInt64,
           fileSize > 0 {
            // File is good
        } else {
            print("❌ File is empty or missing at path: \(url.path)")
            return
        }
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.delegate = self
            audioPlayer?.volume = 1.0
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()
            isPlaying = true
            print("▶️ Playing audio...")
        } catch {
            print("❌ Could not play file: \(error)")
        }
    }
    
    // MARK: - Delegates
    
    // This confirms the file is successfully closed and ready to read
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if flag {
            recordedFileURL = recorder.url
            print("✅ Recording saved successfully: \(recorder.url)")
        } else {
            print("❌ Recording failed to save.")
            recordedFileURL = nil
        }
    }
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        isPlaying = false
        print("⏹️ Playback finished.")
    }
}
