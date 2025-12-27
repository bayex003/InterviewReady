import Foundation
import AVFoundation
import SwiftUI

@Observable
final class AudioService: NSObject, AVAudioRecorderDelegate, AVAudioPlayerDelegate {
    var isRecording = false
    var isPlaying = false
    var recordedFileURL: URL?

    private var audioRecorder: AVAudioRecorder?
    private var audioPlayer: AVAudioPlayer?

    override init() {
        super.init()
    }

    private func setupSessionForRecording() {
        let session = AVAudioSession.sharedInstance()
        do {
            // "playAndRecord" is required for recording
            // "defaultToSpeaker" ensures it plays back loud, not through the earpiece
            // Bluetooth support (fixed: uses modern CategoryOptions)
            try session.setCategory(
                .playAndRecord,
                mode: .default,
                options: [.defaultToSpeaker, .allowBluetooth, .allowBluetoothA2DP]
            )
            try session.setActive(true)
        } catch {
            print("Failed to set up audio session: \(error)")
        }
    }

    private func setupSessionForPlayback() {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playback, mode: .default, options: [])
            try session.setActive(true)
        } catch {
            print("Failed to set up playback session: \(error)")
        }
    }

    func startRecording(id: String) {
        setupSessionForRecording()

        let fileName = "answer_\(id).m4a"
        let path = FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(fileName)

        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]

        do {
            audioRecorder = try AVAudioRecorder(url: path, settings: settings)
            audioRecorder?.delegate = self
            audioRecorder?.record()

            isRecording = true
            recordedFileURL = nil
            print("🎙️ Started recording to: \(path)")
        } catch {
            print("Could not start recording: \(error)")
        }
    }

    func stopRecording() {
        audioRecorder?.stop()
        isRecording = false
        // recordedFileURL is set in delegate callback
    }

    func playRecording() {
        guard let url = recordedFileURL else {
            print("❌ No file URL found to play.")
            return
        }

        // Check file exists and has data
        if let attributes = try? FileManager.default.attributesOfItem(atPath: url.path),
           let fileSize = attributes[.size] as? UInt64,
           fileSize > 0 {
            // OK
        } else {
            print("❌ File is empty or missing at path: \(url.path)")
            return
        }

        do {
            setupSessionForPlayback()
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
