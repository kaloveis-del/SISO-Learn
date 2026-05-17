# Task 7 가이드: 대화형 학습 세션 구현

> **단계**: 4단계 (학습) | **선행 태스크**: Task 4, 5, 6 | **후행 태스크**: Task 8, 9

---

## 목표

쿠키와 대화하듯 학습하는 핵심 화면을 구현한다. 쿠키가 설명하고 → 문제를 내고 → 답변을 받고 → 피드백을 주는 전체 학습 사이클이 이 태스크에서 완성된다.

---

## 체크리스트

- [x] 7.1 `LearningPhase` 열거형 (Task 6에서 이미 정의됨, 확인만)
- [x] 7.2 `StartLearningSessionUseCase.swift` 구현
- [x] 7.3 `SubmitAnswerUseCase.swift` 구현
- [x] 7.4 `RequestHintUseCase.swift` 구현
- [x] 7.5 `SaveProgressUseCase.swift` 구현
- [x] 7.6 `LearningSessionViewModel.swift` 구현
- [x] 7.7 `CookieLearningView.swift` 구현
- [x] 7.8 `SessionCompleteView.swift` 구현
- [x] 7.9 `HomeView.swift` 구현
- [x] 7.10 학습 세션 단위 테스트
- [x] 7.11 학습 흐름 통합 테스트

---

## 상세 구현 가이드

### 7.2 `StartLearningSessionUseCase.swift`

경로: `Modules/Learning/Domain/UseCases/StartLearningSessionUseCase.swift`

```swift
import Foundation

struct SessionStartResult {
    let sessionId: UUID
    let explanation: String
    let quizzes: [Quiz]
}

final class StartLearningSessionUseCase {
    private let aiTutor: AITutorProtocol

    init(aiTutor: AITutorProtocol) {
        self.aiTutor = aiTutor
    }

    func execute(profile: Profile, subject: Subject, difficulty: Difficulty,
                 topic: String, quizCount: Int = 5) async throws -> SessionStartResult {
        // 설명과 Quiz를 동시에 요청 (병렬)
        async let explanation = aiTutor.generateExplanation(
            topic: topic, gradeLevel: profile.gradeLevel, subject: subject)
        async let quizzes = aiTutor.generateQuizzes(
            topic: topic, gradeLevel: profile.gradeLevel,
            subject: subject, difficulty: difficulty, count: quizCount)

        return SessionStartResult(
            sessionId: UUID(),
            explanation: try await explanation,
            quizzes: try await quizzes
        )
    }
}
```

### 7.3 `SubmitAnswerUseCase.swift`

경로: `Modules/Learning/Domain/UseCases/SubmitAnswerUseCase.swift`

```swift
import Foundation

final class SubmitAnswerUseCase {
    private let aiTutor: AITutorProtocol

    init(aiTutor: AITutorProtocol) { self.aiTutor = aiTutor }

    func execute(quiz: Quiz, userAnswer: String,
                 gradeLevel: GradeLevel, hintUsedCount: Int) async throws -> AnswerFeedback {
        // CP-3: 답변 1,000자 제한
        let truncated = String(userAnswer.prefix(GeminiAPILimits.answerMaxChars))
        return try await aiTutor.evaluateAnswer(
            quiz: quiz, userAnswer: truncated, gradeLevel: gradeLevel)
    }
}
```

### 7.4 `RequestHintUseCase.swift`

경로: `Modules/Learning/Domain/UseCases/RequestHintUseCase.swift`

```swift
import Foundation

final class RequestHintUseCase {
    private let aiTutor: AITutorProtocol

    init(aiTutor: AITutorProtocol) { self.aiTutor = aiTutor }

    func execute(quiz: Quiz, hintLevel: Int, gradeLevel: GradeLevel) async throws -> String {
        // CP-2: 힌트 단계 1~3 클램핑
        let clamped = max(1, min(GeminiAPILimits.maxHintLevel, hintLevel))
        return try await aiTutor.generateHint(
            quiz: quiz, hintLevel: clamped, gradeLevel: gradeLevel)
    }
}
```

### 7.5 `SaveProgressUseCase.swift`

경로: `Modules/Learning/Domain/UseCases/SaveProgressUseCase.swift`

```swift
import Foundation

final class SaveProgressUseCase {
    private let sessionRepo: SessionRepositoryProtocol

    init(sessionRepo: SessionRepositoryProtocol) { self.sessionRepo = sessionRepo }

    func execute(sessionId: UUID, profileId: UUID, subject: Subject,
                 difficulty: Difficulty, topic: String,
                 results: [QuizResult], durationSeconds: Int,
                 youtubeVideoId: String? = nil) async throws {
        let correctCount = results.filter { $0.isCorrect }.count
        let accuracyRate = results.isEmpty ? 0.0 : Double(correctCount) / Double(results.count)

        let session = LearningSession(
            id: sessionId, profileId: profileId,
            subject: subject, difficulty: difficulty, topic: topic,
            startedAt: Date().addingTimeInterval(-Double(durationSeconds)),
            completedAt: Date(),
            totalQuizCount: results.count, correctCount: correctCount,
            accuracyRate: accuracyRate, youtubeVideoId: youtubeVideoId,
            durationSeconds: durationSeconds
        )
        try await sessionRepo.save(session: session, results: results)
        try await sessionRepo.updateStreak(profileId: profileId)
    }
}
```

### 7.6 `LearningSessionViewModel.swift`

경로: `Modules/Learning/Presentation/ViewModels/LearningSessionViewModel.swift`

```swift
import SwiftUI

@MainActor
final class LearningSessionViewModel: ObservableObject {

    // MARK: - 상태
    @Published var currentPhase: LearningPhase = .greeting
    @Published var explanation: String = ""
    @Published var quizzes: [Quiz] = []
    @Published var currentQuizIndex: Int = 0
    @Published var userAnswer: String = ""
    @Published var currentFeedback: AnswerFeedback?
    @Published var hints: [String] = []
    @Published var hintCount: Int = 0
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var sessionResults: [QuizResult] = []

    // MARK: - 계산 속성
    var currentQuiz: Quiz? { quizzes[safe: currentQuizIndex] }
    var progress: Double {
        guard !quizzes.isEmpty else { return 0 }
        return Double(currentQuizIndex) / Double(quizzes.count)
    }
    var accuracyRate: Double {
        guard !sessionResults.isEmpty else { return 0 }
        return Double(sessionResults.filter { $0.isCorrect }.count) / Double(sessionResults.count)
    }
    var canRequestHint: Bool { hintCount < GeminiAPILimits.maxHintLevel }
    var isAnswerEmpty: Bool { userAnswer.trimmingCharacters(in: .whitespaces).isEmpty }
    var isAnswerOverLimit: Bool { userAnswer.count > GeminiAPILimits.answerMaxChars }

    // MARK: - 의존성
    private let startSessionUseCase: StartLearningSessionUseCase
    private let submitAnswerUseCase: SubmitAnswerUseCase
    private let requestHintUseCase: RequestHintUseCase
    private let saveProgressUseCase: SaveProgressUseCase
    let cookieVM: CookieViewModel  // View에서 직접 참조

    // MARK: - 세션 컨텍스트
    private var sessionId: UUID?
    private let profile: Profile
    private let subject: Subject
    private let difficulty: Difficulty
    private let topic: String
    private var sessionStartTime = Date()

    init(profile: Profile, subject: Subject, difficulty: Difficulty, topic: String,
         startSessionUseCase: StartLearningSessionUseCase,
         submitAnswerUseCase: SubmitAnswerUseCase,
         requestHintUseCase: RequestHintUseCase,
         saveProgressUseCase: SaveProgressUseCase,
         cookieVM: CookieViewModel = CookieViewModel()) {
        self.profile = profile
        self.subject = subject
        self.difficulty = difficulty
        self.topic = topic
        self.startSessionUseCase = startSessionUseCase
        self.submitAnswerUseCase = submitAnswerUseCase
        self.requestHintUseCase = requestHintUseCase
        self.saveProgressUseCase = saveProgressUseCase
        self.cookieVM = cookieVM
    }
```

    // MARK: - 액션

    func startSession(quizCount: Int = 5) {
        isLoading = true
        sessionStartTime = Date()
        cookieVM.updateForPhase(.greeting, userName: profile.name)
        Task {
            do {
                let result = try await startSessionUseCase.execute(
                    profile: profile, subject: subject,
                    difficulty: difficulty, topic: topic, quizCount: quizCount)
                sessionId = result.sessionId
                explanation = result.explanation
                quizzes = result.quizzes
                currentPhase = .explanation
                cookieVM.speakAIMessage(result.explanation, phase: .explanation)
            } catch { handleError(error) }
            isLoading = false
        }
    }

    func proceedToQuiz() {
        guard !quizzes.isEmpty else { return }
        currentPhase = .quiz
        cookieVM.updateForPhase(.quiz)
    }

    func startAnswering() {
        currentPhase = .answering
        cookieVM.updateForPhase(.answering)
    }

    func requestHint() {
        guard canRequestHint, let quiz = currentQuiz else { return }
        cookieVM.updateForPhase(.hintRequested(hintCount + 1))
        isLoading = true
        Task {
            do {
                let hint = try await requestHintUseCase.execute(
                    quiz: quiz, hintLevel: hintCount + 1, gradeLevel: profile.gradeLevel)
                hints.append(hint)
                hintCount += 1
                currentPhase = .hintRequested(hintCount)
                cookieVM.speakAIMessage(hint, phase: .hintRequested(hintCount))
            } catch { handleError(error) }
            isLoading = false
        }
    }

    func submitAnswer() {
        guard !isAnswerEmpty, !isAnswerOverLimit, let quiz = currentQuiz else { return }
        isLoading = true
        Task {
            do {
                let feedback = try await submitAnswerUseCase.execute(
                    quiz: quiz, userAnswer: userAnswer,
                    gradeLevel: profile.gradeLevel, hintUsedCount: hintCount)
                currentFeedback = feedback
                sessionResults.append(QuizResult(
                    id: UUID(), sessionId: sessionId ?? UUID(),
                    quizQuestion: quiz.question, userAnswer: userAnswer,
                    isCorrect: feedback.isCorrect, score: feedback.score,
                    hintUsedCount: hintCount, feedbackText: feedback.explanation,
                    answeredAt: Date(), timeSpentSeconds: 0))
                currentPhase = .feedback
                cookieVM.updateForPhase(.feedback, isCorrect: feedback.isCorrect,
                                        userName: profile.name)
            } catch { handleError(error) }
            isLoading = false
        }
    }

    func proceedToNextQuiz() {
        userAnswer = ""; hints = []; hintCount = 0; currentFeedback = nil
        if currentQuizIndex + 1 < quizzes.count {
            currentQuizIndex += 1
            currentPhase = .quiz
            cookieVM.updateForPhase(.quiz)
        } else { completeSession() }
    }

    private func completeSession() {
        currentPhase = .sessionComplete
        cookieVM.updateForPhase(.sessionComplete, userName: profile.name)
        Task {
            guard let sid = sessionId else { return }
            let duration = Int(Date().timeIntervalSince(sessionStartTime))
            try? await saveProgressUseCase.execute(
                sessionId: sid, profileId: profile.id,
                subject: subject, difficulty: difficulty, topic: topic,
                results: sessionResults, durationSeconds: duration)
        }
    }

    private func handleError(_ error: Error) {
        if let aiError = error as? AITutorError {
            cookieVM.speakError(aiError)
            errorMessage = aiError.errorDescription
        } else {
            errorMessage = "오류가 생겼어요. 다시 시도해봐! 🥺"
        }
    }
}
```

### 7.7 `CookieLearningView.swift` 레이아웃

경로: `Modules/Learning/Presentation/Views/CookieLearningView.swift`

```
화면 구조:
┌─────────────────────────────────────────┐
│  ← 뒤로   수학 · 보통          [설정]   │  ← NavigationBar
├─────────────────────────────────────────┤
│  [쿠키🐶] [말풍선: 쿠키 메시지]         │  ← CookieBubbleView (고정)
├─────────────────────────────────────────┤
│  ┌─────────────────────────────────┐    │
│  │ ❓ 문제 2/5                     │    │  ← Quiz 카드
│  │ "자, 문제야! 1/2+1/4는? 🤔"    │    │
│  └─────────────────────────────────┘    │
│  ┌─────────────────────────────────┐    │
│  │ ✏️ 쿠키에게 답변하기            │    │  ← 답변 입력
│  │ [TextEditor]                    │    │
│  │ 0/1000자  [💡힌트(3회)] [제출→] │    │
│  └─────────────────────────────────┘    │
├─────────────────────────────────────────┤
│  ████░░░░░░ 2/5                         │  ← 진행 바
└─────────────────────────────────────────┘
```

```swift
struct CookieLearningView: View {
    @StateObject var viewModel: LearningSessionViewModel

    var body: some View {
        VStack(spacing: 0) {
            // 쿠키 말풍선 (항상 상단 고정)
            CookieBubbleView(cookieVM: viewModel.cookieVM)
                .padding(.top, 8)

            ScrollView {
                VStack(spacing: 16) {
                    // 학습 단계별 콘텐츠
                    switch viewModel.currentPhase {
                    case .explanation:
                        explanationCard
                    case .quiz, .answering, .hintRequested:
                        quizCard
                        answerInputCard
                    case .feedback:
                        if let feedback = viewModel.currentFeedback {
                            feedbackCard(feedback)
                        }
                    case .sessionComplete:
                        EmptyView() // SessionCompleteView로 전환
                    default:
                        loadingView
                    }
                }
                .padding()
            }

            // 진행 바
            progressBar
        }
        .navigationBarTitleDisplayMode(.inline)
        .overlay { if viewModel.isLoading { loadingOverlay } }
        .onAppear { viewModel.startSession() }
    }
    // ... 각 카드 구현
}
```

### 7.8 `SessionCompleteView.swift`

```swift
struct SessionCompleteView: View {
    let accuracyRate: Double
    let subject: Subject
    let cookieVM: CookieViewModel
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            CookieBubbleView(cookieVM: cookieVM)
            // 정답률 원형 표시
            ZStack {
                Circle().stroke(Color.orange.opacity(0.2), lineWidth: 12)
                Circle().trim(from: 0, to: accuracyRate)
                    .stroke(Color.orange, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                Text("\(Int(accuracyRate * 100))%")
                    .font(.largeTitle).fontWeight(.bold)
            }
            .frame(width: 150, height: 150)
            Button("홈으로 돌아가기") { onDismiss() }
                .buttonStyle(.borderedProminent).tint(.orange)
                .frame(minHeight: 44)
        }
        .padding()
    }
}
```

### 7.9 `HomeView.swift`

```swift
struct HomeView: View {
    let profile: Profile
    @StateObject private var cookieVM = CookieViewModel()

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // 쿠키 캐릭터 + 인사
                CookieCharacterView(emotion: cookieVM.currentEmotion)
                CookieBubbleView(cookieVM: cookieVM)

                // 과목 선택 그리드
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                    ForEach(Subject.allCases, id: \.self) { subject in
                        SubjectCardView(subject: subject) {
                            // 난이도 선택 → 학습 시작
                        }
                    }
                }
                .padding(.horizontal)
            }
            .navigationTitle("안녕, \(profile.name)! 🐶")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: ProgressView()) {
                        Image(systemName: "chart.bar.fill")
                    }
                }
            }
            .onAppear {
                cookieVM.updateForPhase(.greeting, userName: profile.name)
            }
        }
    }
}
```

### 7.10 단위 테스트

경로: `Tests/UnitTests/Learning/LearningSessionViewModelTests.swift`

```swift
@MainActor
final class LearningSessionViewModelTests: XCTestCase {
    var sut: LearningSessionViewModel!
    var mockAI: MockAITutor!

    override func setUp() {
        super.setUp()
        mockAI = MockAITutor()
        mockAI.quizzesToReturn = [Quiz.mock()]
        sut = LearningSessionViewModel(
            profile: .mock(), subject: .math, difficulty: .normal, topic: "분수",
            startSessionUseCase: StartLearningSessionUseCase(aiTutor: mockAI),
            submitAnswerUseCase: SubmitAnswerUseCase(aiTutor: mockAI),
            requestHintUseCase: RequestHintUseCase(aiTutor: mockAI),
            saveProgressUseCase: SaveProgressUseCase(sessionRepo: MockSessionRepository()))
    }

    func test_requestHint_cannotExceedThree() async {
        sut.quizzes = [Quiz.mock()]
        sut.currentPhase = .quiz
        await sut.requestHint(); await sut.requestHint(); await sut.requestHint()
        XCTAssertFalse(sut.canRequestHint)
        XCTAssertEqual(sut.hintCount, 3)
    }

    func test_submitAnswer_blockedWhenOverLimit() async {
        sut.userAnswer = String(repeating: "가", count: 1001)
        XCTAssertTrue(sut.isAnswerOverLimit)
        await sut.submitAnswer()
        XCTAssertEqual(mockAI.evaluateAnswerCallCount, 0)
    }

    func test_accuracyRate_calculatedCorrectly() {
        sut.sessionResults = [
            QuizResult.mock(isCorrect: true), QuizResult.mock(isCorrect: true),
            QuizResult.mock(isCorrect: false)
        ]
        XCTAssertEqual(sut.accuracyRate, 2.0/3.0, accuracy: 0.001)
    }
}
```

---

## 완료 기준 확인

| 항목 | 확인 방법 |
|------|-----------|
| 학습 시작 | 과목/난이도 선택 후 쿠키 인사 → 설명 → Quiz 순서 확인 |
| 쿠키 감정 전환 | 정답 시 🎉, 오답 시 🥺 감정 전환 확인 |
| 힌트 3단계 제한 | 3회 후 힌트 버튼 비활성화 확인 |
| 세션 완료 저장 | 완료 후 Progress 화면에서 기록 확인 |
| 단위 테스트 | `LearningSessionViewModelTests` 모두 통과 |

---

## 다음 단계

Task 7 완료 후 **Task 8 (YouTube 연계)**, **Task 9 (Progress)**, **Task 10 (에러 처리)** 를 병렬로 진행할 수 있다.
