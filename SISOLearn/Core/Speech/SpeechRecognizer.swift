import Speech
import SwiftUI
import Observation

@Observable
@MainActor
final class SpeechRecognizer {
    var transcript: String = ""
    var isRecording: Bool = false
    var errorMessage: String?

    @ObservationIgnored private var audioEngine = AVAudioEngine()
    @ObservationIgnored private var recognitionTask: SFSpeechRecognitionTask?
    @ObservationIgnored private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    @ObservationIgnored private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "ko-KR"))

    func requestPermission() {
        SFSpeechRecognizer.requestAuthorization { status in
            Task { @MainActor in
                if status != .authorized {
                    self.errorMessage = "음성 인식 권한이 필요해요."
                }
            }
        }
    }

    func startRecording() {
        guard let speechRecognizer, speechRecognizer.isAvailable else { return }
        stopRecording()
        let audioSession = AVAudioSession.sharedInstance()
        try? audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
        try? audioSession.setActive(true, options: .notifyOthersOnDeactivation)

        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest else { return }
        recognitionRequest.shouldReportPartialResults = true

        let inputNode = audioEngine.inputNode
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: inputNode.outputFormat(forBus: 0)) { buffer, _ in
            recognitionRequest.append(buffer)
        }

        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            Task { @MainActor in
                if let result { self?.transcript = result.bestTranscription.formattedString }
                if error != nil || (result?.isFinal ?? false) { self?.stopRecording() }
            }
        }
        try? audioEngine.start()
        isRecording = true
    }

    func stopRecording() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        recognitionRequest = nil
        recognitionTask = nil
        isRecording = false
    }
}
