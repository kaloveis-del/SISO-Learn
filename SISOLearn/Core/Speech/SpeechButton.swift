import SwiftUI

struct SpeechButton: View {
    @Binding var inputText: String
    @State private var speechRecognizer = SpeechRecognizer()

    var body: some View {
        VStack(spacing: 4) {
            Button {
                if speechRecognizer.isRecording {
                    speechRecognizer.stopRecording()
                    if !speechRecognizer.transcript.isEmpty {
                        inputText = inputText.isEmpty ? speechRecognizer.transcript : inputText + " " + speechRecognizer.transcript
                    }
                    speechRecognizer.transcript = ""
                } else {
                    speechRecognizer.requestPermission()
                    speechRecognizer.startRecording()
                }
            } label: {
                Image(systemName: speechRecognizer.isRecording ? "mic.fill" : "mic")
                    .foregroundColor(speechRecognizer.isRecording ? .red : .orange)
                    .font(.title2)
                    .padding(10)
                    .background(RoundedRectangle(cornerRadius: 12).fill(speechRecognizer.isRecording ? Color.red.opacity(0.1) : Color.orange.opacity(0.1)))
            }
            .frame(minWidth: 44, minHeight: 44)

            if speechRecognizer.isRecording {
                Text("듣는 중...").font(.caption2).foregroundColor(.red)
            }
        }
    }
}
