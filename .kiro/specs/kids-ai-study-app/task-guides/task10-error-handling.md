# Task 10 가이드: 에러 처리 및 오프라인 대응 구현

> **단계**: 5단계 (확장) | **선행 태스크**: Task 7 | **후행 태스크**: Task 11

---

## 목표

네트워크 오류, API 한도 초과, 오프라인 상황에서 쿠키가 친근한 메시지로 안내하도록 구현한다. 아이들이 오류 상황에서 당황하지 않도록 쿠키의 위로(🥺) 감정과 함께 표시한다.

---

## 체크리스트

- [x] 10.1 `ErrorView.swift` 구현
- [x] 10.2 쿠키 에러 메시지 연동 (CookieViewModel.speakError)
- [x] 10.3 오프라인 감지 UI 처리
- [x] 10.4 API 분당 한도 초과 처리 (60초 타이머)
- [x] 10.5 일일 한도 초과 처리
- [x] 10.6 CoreData 저장 실패 처리
- [x] 10.7 에러 처리 단위 테스트

---

## 상세 구현 가이드

### 10.1 `ErrorView.swift`

경로: `Core/Views/ErrorView.swift`

```swift
import SwiftUI

struct ErrorView: View {
    let error: AITutorError
    let retryAction: (() -> Void)?
    let settingsAction: (() -> Void)?

    var body: some View {
        VStack(spacing: 20) {
            // 에러 아이콘
            Image(systemName: iconName)
                .font(.system(size: 56))
                .foregroundColor(.orange)

            // 에러 메시지
            Text(error.errorDescription ?? "오류가 생겼어요")
                .font(.headline)
                .multilineTextAlignment(.center)
                .foregroundColor(.primary)

            // 액션 버튼
            VStack(spacing: 12) {
                if let retry = retryAction, error.isRetryable {
                    Button("다시 시도") { retry() }
                        .buttonStyle(.borderedProminent).tint(.orange)
                        .frame(minHeight: 44)
                }
                if case .invalidAPIKey = error {
                    Button("API 키 설정하기") { settingsAction?() }
                        .buttonStyle(.bordered)
                        .frame(minHeight: 44)
                }
            }
        }
        .padding(32)
        .background(Color(.systemBackground))
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.1), radius: 8)
        .padding()
    }

    private var iconName: String {
        switch error {
        case .offline, .networkError:           return "wifi.slash"
        case .rateLimitExceeded:                return "clock.badge.exclamationmark"
        case .dailyLimitExceeded:               return "moon.zzz.fill"
        case .invalidAPIKey:                    return "key.slash"
        case .parseError:                       return "exclamationmark.triangle"
        }
    }
}
```

### 10.2 쿠키 에러 메시지 연동

`CookieViewModel.speakError()`는 Task 6에서 이미 구현됨.
`LearningSessionViewModel.handleError()`에서 자동 호출됨.

에러 발생 시 흐름:
```
AI 요청 실패
  → LearningSessionViewModel.handleError(error)
    → cookieVM.speakError(error)  // 쿠키가 위로(🥺) 감정으로 메시지 표시
    → errorMessage 설정           // ErrorView 표시
```

### 10.3 오프라인 감지 UI 처리

`CookieLearningView`에 NetworkMonitor 연동:

```swift
struct CookieLearningView: View {
    @EnvironmentObject private var networkMonitor: NetworkMonitor
    @StateObject var viewModel: LearningSessionViewModel

    var body: some View {
        ZStack {
            // 기존 학습 화면
            mainContent

            // 오프라인 배너
            if !networkMonitor.isConnected {
                VStack {
                    offlineBanner
                    Spacer()
                }
            }
        }
        .onChange(of: networkMonitor.isConnected) { isConnected in
            if !isConnected {
                viewModel.cookieVM.speak(
                    CookieMessageTemplates.random(from: CookieMessageTemplates.offlineMessages),
                    emotion: .comforting)
            }
        }
    }

    private var offlineBanner: some View {
        HStack(spacing: 8) {
            Image(systemName: "wifi.slash")
            Text("인터넷 연결이 없어요")
                .font(.subheadline).fontWeight(.medium)
        }
        .foregroundColor(.white)
        .padding(.horizontal, 16).padding(.vertical, 8)
        .background(Color.red.opacity(0.85))
        .cornerRadius(20)
        .padding(.top, 8)
        .transition(.move(edge: .top).combined(with: .opacity))
        .animation(.easeInOut, value: networkMonitor.isConnected)
    }
}
```

### 10.4 API 분당 한도 초과 처리 (60초 타이머)

`LearningSessionViewModel`에 타이머 로직 추가:

```swift
// LearningSessionViewModel 내부에 추가
@Published var rateLimitCountdown: Int = 0
private var countdownTimer: Timer?

private func handleRateLimitError() {
    rateLimitCountdown = 60
    cookieVM.speak(
        CookieMessageTemplates.random(from: CookieMessageTemplates.rateLimitMessages),
        emotion: .comforting)

    countdownTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
        guard let self else { timer.invalidate(); return }
        Task { @MainActor in
            self.rateLimitCountdown -= 1
            if self.rateLimitCountdown <= 0 {
                timer.invalidate()
                self.countdownTimer = nil
                // 자동 재시도
                self.submitAnswer()
            }
        }
    }
}
```

`CookieLearningView`에 카운트다운 표시:

```swift
// 분당 한도 초과 시 카운트다운 표시
if viewModel.rateLimitCountdown > 0 {
    Text("⏳ \(viewModel.rateLimitCountdown)초 후 다시 시도해요")
        .font(.caption).foregroundColor(.orange)
        .padding(.horizontal, 12).padding(.vertical, 6)
        .background(Color.orange.opacity(0.1))
        .cornerRadius(12)
}
```

### 10.5 일일 한도 초과 처리

`handleError()`에서 `dailyLimitExceeded` 케이스 처리:

```swift
private func handleError(_ error: Error) {
    if let aiError = error as? AITutorError {
        cookieVM.speakError(aiError)
        errorMessage = aiError.errorDescription

        // 일일 한도 초과 시 학습 중단
        if case .dailyLimitExceeded = aiError {
            currentPhase = .sessionComplete  // 세션 강제 종료
            // 지금까지의 결과 저장
            completeSession()
        }
        // 분당 한도 초과 시 타이머 시작
        if case .rateLimitExceeded = aiError {
            handleRateLimitError()
        }
    } else {
        errorMessage = "오류가 생겼어요. 다시 시도해봐! 🥺"
    }
}
```

### 10.6 CoreData 저장 실패 처리

`SaveProgressUseCase`에서 실패 시 재시도 버튼 제공:

```swift
// LearningSessionViewModel에 추가
@Published var saveFailedError: Error?
@Published var showSaveRetry = false

private func completeSession() {
    currentPhase = .sessionComplete
    cookieVM.updateForPhase(.sessionComplete, userName: profile.name)
    Task {
        guard let sid = sessionId else { return }
        let duration = Int(Date().timeIntervalSince(sessionStartTime))
        do {
            try await saveProgressUseCase.execute(
                sessionId: sid, profileId: profile.id,
                subject: subject, difficulty: difficulty, topic: topic,
                results: sessionResults, durationSeconds: duration)
        } catch {
            saveFailedError = error
            showSaveRetry = true
            cookieVM.speak("학습 기록 저장에 실패했어요 🥺 다시 시도해볼까?",
                           emotion: .comforting)
        }
    }
}
```

`SessionCompleteView`에 재시도 버튼 추가:

```swift
if viewModel.showSaveRetry {
    Button("기록 다시 저장하기") {
        viewModel.retrySave()
    }
    .buttonStyle(.bordered)
    .frame(minHeight: 44)
}
```

### 10.7 에러 처리 단위 테스트

경로: `Tests/UnitTests/Error/ErrorHandlingTests.swift`

```swift
@MainActor
final class ErrorHandlingTests: XCTestCase {

    func test_offlineError_cookieSpeaksComforting() {
        let cookieVM = CookieViewModel()
        cookieVM.speakError(.offline)
        XCTAssertEqual(cookieVM.currentEmotion, .comforting)
    }

    func test_rateLimitError_cookieSpeaksComforting() {
        let cookieVM = CookieViewModel()
        cookieVM.speakError(.rateLimitExceeded)
        XCTAssertEqual(cookieVM.currentEmotion, .comforting)
    }

    func test_invalidAPIKeyError_isNotRetryable() {
        XCTAssertFalse(AITutorError.invalidAPIKey.isRetryable)
    }

    func test_networkError_isRetryable() {
        XCTAssertTrue(AITutorError.networkError("test").isRetryable)
    }

    func test_dailyLimitError_isNotRetryable() {
        XCTAssertFalse(AITutorError.dailyLimitExceeded.isRetryable)
    }
}
```

---

## 에러 유형별 처리 요약표

| 에러 | 쿠키 감정 | 처리 방식 | 재시도 |
|------|-----------|-----------|--------|
| 오프라인 | 🥺 위로 | 오프라인 배너 + 쿠키 메시지 | 수동 |
| 분당 한도 초과 | 🥺 위로 | 60초 카운트다운 후 자동 재시도 | 자동 |
| 일일 한도 초과 | 🥺 위로 | 세션 강제 종료 + 내일 안내 | 없음 |
| API Key 오류 | 🥺 위로 | 설정 화면 이동 버튼 | 없음 |
| 네트워크 오류 | 🥺 위로 | 재시도 버튼 표시 | 수동 |
| 저장 실패 | 🥺 위로 | 재시도 버튼 표시 | 수동 |

---

## 완료 기준 확인

| 항목 | 확인 방법 |
|------|-----------|
| 오프라인 배너 | 비행기 모드 전환 시 상단 배너 + 쿠키 메시지 표시 |
| 분당 한도 | 잘못된 API Key로 429 응답 시뮬레이션 |
| 에러 테스트 | `ErrorHandlingTests` 모두 통과 |

---

## 다음 단계

Task 10 완료 후 **Task 11 (UI 완성도)** 로 진행한다.
