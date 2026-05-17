# Task 8 가이드: YouTube 연계 학습 구현

> **단계**: 5단계 (확장) | **선행 태스크**: Task 7 | **후행 태스크**: Task 11

---

## 목표

YouTube 영상을 보면서 쿠키와 함께 학습하는 화면을 구현한다. iPad 화면을 좌측(영상) 50% + 우측(쿠키 학습 패널) 50%로 분할한다.

---

## 체크리스트

- [ ] 8.1 `YouTubeService.swift` 구현
- [ ] 8.2 `YouTubePlayerView.swift` 구현 (WKWebView)
- [ ] 8.3 `YouTubeLearningView.swift` 구현 (분할 레이아웃)
- [ ] 8.4 YouTube URL 입력 화면 구현
- [ ] 8.5 `YouTubeServiceTests.swift` 작성

---

## 상세 구현 가이드

### 8.1 `YouTubeService.swift`

경로: `Modules/YouTube/YouTubeService.swift`

```swift
import Foundation

struct YouTubeService {

    /// YouTube URL에서 videoId 추출
    /// 지원 형식:
    /// - https://www.youtube.com/watch?v=VIDEO_ID
    /// - https://youtu.be/VIDEO_ID
    /// - https://www.youtube.com/embed/VIDEO_ID
    func extractVideoId(from urlString: String) -> String? {
        guard let url = URL(string: urlString) else { return nil }

        // youtu.be 단축 URL
        if url.host == "youtu.be" {
            return url.pathComponents.dropFirst().first
        }

        // youtube.com/watch?v=
        if let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
           let item = components.queryItems?.first(where: { $0.name == "v" }) {
            return item.value
        }

        // youtube.com/embed/VIDEO_ID
        if let idx = url.pathComponents.firstIndex(of: "embed") {
            let next = url.pathComponents.index(after: idx)
            if next < url.pathComponents.endIndex {
                return url.pathComponents[next]
            }
        }
        return nil
    }

    /// 썸네일 URL 생성
    func thumbnailURL(for videoId: String) -> URL? {
        URL(string: "https://img.youtube.com/vi/\(videoId)/hqdefault.jpg")
    }
}
```

### 8.2 `YouTubePlayerView.swift`

경로: `Modules/YouTube/Views/YouTubePlayerView.swift`

```swift
import SwiftUI
import WebKit

struct YouTubePlayerView: UIViewRepresentable {
    let videoId: String
    @Binding var isReady: Bool

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator
        webView.scrollView.isScrollEnabled = false
        webView.backgroundColor = .black
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        webView.loadHTMLString(embedHTML, baseURL: URL(string: "https://www.youtube.com"))
    }

    func makeCoordinator() -> Coordinator { Coordinator(isReady: $isReady) }

    private var embedHTML: String {
        """
        <!DOCTYPE html><html><head>
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <style>body{margin:0;background:#000}
        .vc{position:relative;width:100%;padding-bottom:56.25%;height:0}
        iframe{position:absolute;top:0;left:0;width:100%;height:100%;border:none}
        </style></head><body>
        <div class="vc"><iframe
          src="https://www.youtube.com/embed/\(videoId)?playsinline=1&rel=0&modestbranding=1"
          allow="accelerometer;autoplay;clipboard-write;encrypted-media;gyroscope;picture-in-picture"
          allowfullscreen></iframe></div></body></html>
        """
    }

    class Coordinator: NSObject, WKNavigationDelegate {
        @Binding var isReady: Bool
        init(isReady: Binding<Bool>) { _isReady = isReady }
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            isReady = true
        }
    }
}
```

### 8.3 `YouTubeLearningView.swift` — 분할 레이아웃

경로: `Modules/YouTube/Views/YouTubeLearningView.swift`

```
iPad 가로 모드 레이아웃:
┌──────────────────────┬──────────────────────────────┐
│                      │  [쿠키🐶] [말풍선]            │
│   YouTube 영상       │  ┌──────────────────────────┐ │
│   (WKWebView)        │  │ ❓ 문제                  │ │
│   16:9 비율          │  └──────────────────────────┘ │
│                      │  ┌──────────────────────────┐ │
│                      │  │ ✏️ 답변 입력              │ │
│                      │  │ [힌트] [제출]             │ │
│                      │  └──────────────────────────┘ │
├──────────────────────┴──────────────────────────────┤
│  진행: ████░░░░ 2/5                                  │
└─────────────────────────────────────────────────────┘
```

```swift
struct YouTubeLearningView: View {
    @StateObject var viewModel: LearningSessionViewModel
    let videoId: String
    @State private var isVideoReady = false

    var body: some View {
        GeometryReader { geo in
            HStack(spacing: 0) {
                // 좌측 50%: YouTube 영상
                VStack {
                    YouTubePlayerView(videoId: videoId, isReady: $isVideoReady)
                        .aspectRatio(16/9, contentMode: .fit)
                        .frame(maxWidth: .infinity)
                    Spacer()
                }
                .frame(width: geo.size.width * 0.5)
                .background(Color.black)

                Divider()

                // 우측 50%: 쿠키 학습 패널
                CookieLearningView(viewModel: viewModel)
                    .frame(width: geo.size.width * 0.5)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { viewModel.startSession() }
    }
}
```

### 8.4 YouTube URL 입력 화면

경로: `Modules/YouTube/Views/YouTubeURLInputView.swift`

```swift
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

            // URL 입력
            HStack {
                TextField("YouTube URL을 붙여넣어봐!", text: $urlInput)
                    .textFieldStyle(.roundedBorder)
                    .autocorrectionDisabled()
                Button("확인") { extractVideoId() }
                    .buttonStyle(.borderedProminent).tint(.orange)
                    .disabled(urlInput.isEmpty)
                    .frame(minHeight: 44)
            }

            // 썸네일 미리보기
            if let vid = videoId {
                AsyncImage(url: youtubeService.thumbnailURL(for: vid)) { image in
                    image.resizable().aspectRatio(16/9, contentMode: .fit)
                        .cornerRadius(12)
                } placeholder: { ProgressView() }

                if !extractedTopic.isEmpty {
                    Text("📚 학습 주제: \(extractedTopic)")
                        .font(.headline).foregroundColor(.orange)
                }

                NavigationLink("쿠키랑 공부하기! 🐾") {
                    YouTubeLearningView(
                        viewModel: makeViewModel(videoId: vid),
                        videoId: vid)
                }
                .buttonStyle(.borderedProminent).tint(.orange)
                .frame(minHeight: 44)
            }
        }
        .padding()
        .navigationTitle("YouTube 연계 학습")
    }

    private func extractVideoId() {
        guard let vid = youtubeService.extractVideoId(from: urlInput) else { return }
        videoId = vid
        isLoading = true
        Task {
            extractedTopic = (try? await aiTutor.extractTopicFromVideo(
                videoTitle: urlInput, subject: subject, gradeLevel: profile.gradeLevel)) ?? ""
            isLoading = false
        }
    }

    private func makeViewModel(videoId: String) -> LearningSessionViewModel {
        // AppDependencyContainer에서 생성하는 방식으로 교체 권장
        LearningSessionViewModel(
            profile: profile, subject: subject, difficulty: difficulty,
            topic: extractedTopic.isEmpty ? "YouTube 영상 학습" : extractedTopic,
            startSessionUseCase: StartLearningSessionUseCase(aiTutor: aiTutor),
            submitAnswerUseCase: SubmitAnswerUseCase(aiTutor: aiTutor),
            requestHintUseCase: RequestHintUseCase(aiTutor: aiTutor),
            saveProgressUseCase: SaveProgressUseCase(sessionRepo: SessionRepository()))
    }
}
```

### 8.5 `YouTubeServiceTests.swift`

경로: `Tests/UnitTests/YouTube/YouTubeServiceTests.swift`

```swift
import XCTest
@testable import SISOLearn

final class YouTubeServiceTests: XCTestCase {
    let sut = YouTubeService()

    func test_extractVideoId_watchURL() {
        let id = sut.extractVideoId(from: "https://www.youtube.com/watch?v=dQw4w9WgXcQ")
        XCTAssertEqual(id, "dQw4w9WgXcQ")
    }

    func test_extractVideoId_shortURL() {
        let id = sut.extractVideoId(from: "https://youtu.be/dQw4w9WgXcQ")
        XCTAssertEqual(id, "dQw4w9WgXcQ")
    }

    func test_extractVideoId_embedURL() {
        let id = sut.extractVideoId(from: "https://www.youtube.com/embed/dQw4w9WgXcQ")
        XCTAssertEqual(id, "dQw4w9WgXcQ")
    }

    func test_extractVideoId_invalidURL_returnsNil() {
        XCTAssertNil(sut.extractVideoId(from: "https://naver.com"))
    }

    func test_thumbnailURL_format() {
        let url = sut.thumbnailURL(for: "dQw4w9WgXcQ")
        XCTAssertEqual(url?.absoluteString,
                       "https://img.youtube.com/vi/dQw4w9WgXcQ/hqdefault.jpg")
    }
}
```

---

## 완료 기준 확인

| 항목 | 확인 방법 |
|------|-----------|
| URL 파싱 | 3가지 YouTube URL 형식 모두 videoId 추출 확인 |
| 분할 레이아웃 | iPad 가로 모드에서 50:50 분할 확인 |
| 영상 재생 | WKWebView에서 인라인 재생 확인 |
| 단위 테스트 | `YouTubeServiceTests` 모두 통과 |

---

## 다음 단계

Task 8 완료 후 **Task 11 (UI 완성도)** 에서 레이아웃을 다듬는다.
