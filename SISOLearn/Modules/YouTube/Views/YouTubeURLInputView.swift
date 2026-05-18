import SwiftUI

struct YouTubeURLInputView: View {
    @State private var urlInput = ""
    @State private var videoId: String?
    @State private var extractedTopic = ""
    @State private var isLoading = false
    let profile: Profile
    let subject: Subject
    let difficulty: Difficulty
    let aiTutor: AITutorProtocol

    private let youtubeService = YouTubeService()

    var body: some View {
        VStack(spacing: 20) {
            Text("🐶 어떤 영상으로 공부할까?")
                .font(.title2).fontWeight(.bold)

            HStack {
                TextField("YouTube URL을 붙여넣어봐!", text: $urlInput)
                    .textFieldStyle(.roundedBorder)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                Button("확인") { extractVideo() }
                    .buttonStyle(.borderedProminent).tint(.orange)
                    .disabled(urlInput.isEmpty)
                    .frame(minHeight: 44)
            }

            if let vid = videoId {
                AsyncImage(url: youtubeService.thumbnailURL(for: vid)) { image in
                    image.resizable().aspectRatio(16/9, contentMode: .fit).cornerRadius(12)
                } placeholder: { ProgressView() }

                if !extractedTopic.isEmpty {
                    Text("📚 학습 주제: \(extractedTopic)")
                        .font(.headline).foregroundColor(.orange)
                }

                NavigationLink("쿠키랑 공부하기! 🐾") {
                    YouTubeLearningView(
                        viewModel: makeViewModel(),
                        videoId: vid)
                }
                .buttonStyle(.borderedProminent).tint(.orange).frame(minHeight: 44)
            }
        }
        .padding()
        .navigationTitle("YouTube 연계 학습")
    }

    private func extractVideo() {
        guard let vid = youtubeService.extractVideoId(from: urlInput) else { return }
        videoId = vid
        isLoading = true
        Task {
            extractedTopic = (try? await aiTutor.extractTopicFromVideo(
                videoTitle: urlInput, subject: subject, gradeLevel: profile.gradeLevel)) ?? ""
            isLoading = false
        }
    }

    private func makeViewModel() -> LearningSessionViewModel {
        LearningSessionViewModel(
            profile: profile, subject: subject, difficulty: difficulty,
            topic: extractedTopic.isEmpty ? "YouTube 영상 학습" : extractedTopic,
            startSessionUseCase: StartLearningSessionUseCase(aiTutor: aiTutor),
            submitAnswerUseCase: SubmitAnswerUseCase(aiTutor: aiTutor),
            requestHintUseCase: RequestHintUseCase(aiTutor: aiTutor),
            saveProgressUseCase: SaveProgressUseCase(sessionRepo: SessionRepository()), cookieVM: CookieViewModel())
    }
}
