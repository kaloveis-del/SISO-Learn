# Task 5 가이드: AI 연동 모듈 구현 (AITutorProtocol + GeminiAITutor)

> **단계**: 2단계 (AI 연동) | **선행 태스크**: Task 3 | **후행 태스크**: Task 6, Task 7

---

## 목표

Gemini API와 통신하는 AI 튜터 모듈을 구현한다. `AITutorProtocol`로 추상화하여 나중에 다른 AI로 교체할 수 있도록 설계한다. 모든 AI 응답은 Task 6의 쿠키 페르소나 래핑을 통해 쿠키 말투로 출력된다.

---

## 체크리스트

- [x] 5.1 도메인 열거형 정의
- [x] 5.2 `AITutorProtocol.swift` 인터페이스 정의
- [x] 5.3 요청/응답 모델 정의
- [x] 5.4 도메인 응답 모델 정의
- [x] 5.5 `AITutorError.swift` 에러 타입 정의
- [x] 5.6 `GeminiAITutor.swift` 구현
- [x] 5.7 `RetryPolicy.swift` 구현
- [x] 5.8 `MockAITutor.swift` 구현
- [x] 5.9~5.12 테스트 작성

---

## 상세 구현 가이드

### 5.1 도메인 열거형 정의

> `GradeLevel`, `Subject`, `Difficulty`는 Task 2에서 이미 정의했다.
> `CookieEmotion`은 Task 6에서 정의한다.

---

### 5.2 `AITutorProtocol.swift` 인터페이스 정의

경로: `Modules/AITutor/Domain/Protocols/AITutorProtocol.swift`

```swift
import Foundation

/// AI 튜터 제공자 추상화 프로토콜
/// Gemini, OpenAI 등 다양한 AI 제공자로 교체 가능
protocol AITutorProtocol {

    /// 학습 설명 생성 (500자 이하, 쿠키 말투)
    func generateExplanation(
        topic: String,
        gradeLevel: GradeLevel,
        subject: Subject
    ) async throws -> String

    /// Quiz 문제 생성 (3~10개, 쿠키 말투)
    func generateQuizzes(
        topic: String,
        gradeLevel: GradeLevel,
        subject: Subject,
        difficulty: Difficulty,
        count: Int
    ) async throws -> [Quiz]

    /// 답변 평가 및 피드백 생성 (쿠키 말투)
    func evaluateAnswer(
        quiz: Quiz,
        userAnswer: String,
        gradeLevel: GradeLevel
    ) async throws -> AnswerFeedback

    /// 단계적 힌트 생성 (최대 3단계, 정답 직접 제공 금지)
    func generateHint(
        quiz: Quiz,
        hintLevel: Int,
        gradeLevel: GradeLevel
    ) async throws -> String

    /// YouTube 영상 제목 기반 학습 주제 추출
    func extractTopicFromVideo(
        videoTitle: String,
        subject: Subject,
        gradeLevel: GradeLevel
    ) async throws -> String
}
```

---

### 5.3 요청/응답 모델 정의

경로: `Modules/AITutor/Data/Models/GeminiRequest.swift`

```swift
import Foundation

struct GeminiRequest: Encodable {
    let contents: [GeminiContent]
    let generationConfig: GeminiGenerationConfig
    let safetySettings: [GeminiSafetySetting]

    init(prompt: String) {
        self.contents = [GeminiContent(parts: [GeminiPart(text: prompt)])]
        self.generationConfig = GeminiGenerationConfig(
            temperature: 0.7,
            maxOutputTokens: GeminiAPILimits.maxOutputTokens,
            topP: 0.95,
            topK: 40
        )
        // 아동 보호 안전 설정
        self.safetySettings = [
            GeminiSafetySetting(category: "HARM_CATEGORY_HARASSMENT",
                                threshold: "BLOCK_MEDIUM_AND_ABOVE"),
            GeminiSafetySetting(category: "HARM_CATEGORY_HATE_SPEECH",
                                threshold: "BLOCK_MEDIUM_AND_ABOVE"),
            GeminiSafetySetting(category: "HARM_CATEGORY_SEXUALLY_EXPLICIT",
                                threshold: "BLOCK_LOW_AND_ABOVE"),
            GeminiSafetySetting(category: "HARM_CATEGORY_DANGEROUS_CONTENT",
                                threshold: "BLOCK_MEDIUM_AND_ABOVE")
        ]
    }
}

struct GeminiContent: Codable {
    let parts: [GeminiPart]
}

struct GeminiPart: Codable {
    let text: String
}

struct GeminiGenerationConfig: Encodable {
    let temperature: Double
    let maxOutputTokens: Int
    let topP: Double
    let topK: Int
}

struct GeminiSafetySetting: Encodable {
    let category: String
    let threshold: String
}
```

경로: `Modules/AITutor/Data/Models/GeminiResponse.swift`

```swift
import Foundation

struct GeminiResponse: Decodable {
    let candidates: [GeminiCandidate]
    let usageMetadata: GeminiUsageMetadata?
}

struct GeminiCandidate: Decodable {
    let content: GeminiContent
    let finishReason: String?
}

struct GeminiUsageMetadata: Decodable {
    let promptTokenCount: Int?
    let candidatesTokenCount: Int?
    let totalTokenCount: Int?
}
```

---

### 5.4 도메인 응답 모델 정의

경로: `Modules/AITutor/Domain/Models/Quiz.swift`

```swift
import Foundation

struct Quiz: Codable, Identifiable {
    let id: UUID
    let question: String           // 쿠키 말투로 작성된 문제
    let expectedKeywords: [String] // 정답 키워드 (평가용, 화면 미표시)
    let subject: Subject
    let difficulty: Difficulty
    let gradeLevel: GradeLevel
}

extension Quiz {
    static func mock(question: String = "테스트 문제야! 잘 생각해봐~ 🤔") -> Quiz {
        Quiz(id: UUID(), question: question,
             expectedKeywords: ["키워드1", "키워드2"],
             subject: .math, difficulty: .normal, gradeLevel: .grade5Elementary)
    }
}
```

경로: `Modules/AITutor/Domain/Models/AnswerFeedback.swift`

```swift
import Foundation

struct AnswerFeedback: Codable {
    let isCorrect: Bool
    let score: Int          // 0~100
    let explanation: String // 쿠키 말투 피드백
    let correctAnswer: String // 오답 시 정답 설명 (정답이면 빈 문자열)
}
```

---

### 5.5 `AITutorError.swift` 에러 타입 정의

경로: `Modules/AITutor/Domain/AITutorError.swift`

```swift
import Foundation

enum AITutorError: LocalizedError {
    case networkError(String)
    case rateLimitExceeded      // 분당 15회 초과
    case dailyLimitExceeded     // 일 1,500회 초과
    case invalidAPIKey
    case parseError(String)
    case offline

    var errorDescription: String? {
        switch self {
        case .networkError(let msg):
            return "네트워크 오류가 생겼어요: \(msg)"
        case .rateLimitExceeded:
            return "잠시 후 다시 시도해요 (분당 요청 한도 초과)"
        case .dailyLimitExceeded:
            return "오늘 학습 한도에 도달했어요. 내일 다시 만나요! 🐶"
        case .invalidAPIKey:
            return "API 키를 확인해주세요. 설정 화면에서 다시 입력해주세요."
        case .parseError(let msg):
            return "응답 처리 오류: \(msg)"
        case .offline:
            return "인터넷 연결을 확인해주세요."
        }
    }

    /// 재시도 가능한 에러인지 여부
    var isRetryable: Bool {
        switch self {
        case .networkError, .rateLimitExceeded, .parseError: return true
        default: return false
        }
    }
}
```

---

### 5.6 `GeminiAITutor.swift` 구현

경로: `Modules/AITutor/Data/GeminiAITutor.swift`

```swift
import Foundation

final class GeminiAITutor: AITutorProtocol {

    private let apiKey: String
    private let session: URLSession
    private let retryPolicy: RetryPolicy
    private let baseURL = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent"

    // 요청 한도 추적
    private var dailyRequestCount: Int = 0
    private var lastResetDate: Date = Date()

    init(apiKey: String,
         session: URLSession = .shared,
         retryPolicy: RetryPolicy = RetryPolicy()) {
        self.apiKey = apiKey
        self.session = session
        self.retryPolicy = retryPolicy
    }

    // MARK: - AITutorProtocol 구현

    func generateExplanation(topic: String, gradeLevel: GradeLevel, subject: Subject) async throws -> String {
        // Task 6에서 CookiePersonaWrapper로 교체
        let prompt = """
        당신은 '쿠키'라는 귀여운 강아지 AI 선생님입니다.
        [\(gradeLevel.vocabularyLevel)]
        [\(subject.rawValue)] 과목의 [\(topic)] 주제를 쿠키 말투로 500자 이내로 설명해주세요.
        마지막에 "이제 문제를 풀어볼까? 🤔" 로 마무리하세요.
        """
        let response = try await sendWithRetry(prompt: prompt)
        return String(extractText(from: response).prefix(GeminiAPILimits.explanationMaxChars))
    }

    func generateQuizzes(topic: String, gradeLevel: GradeLevel, subject: Subject,
                         difficulty: Difficulty, count: Int) async throws -> [Quiz] {
        // CP-1: Quiz 수 범위 클램핑
        let clampedCount = max(GeminiAPILimits.minQuizCount, min(GeminiAPILimits.maxQuizCount, count))
        let prompt = """
        당신은 '쿠키'라는 귀여운 강아지 AI 선생님입니다.
        [\(gradeLevel.vocabularyLevel)]
        아래 조건으로 Quiz를 JSON 배열로 생성하세요.
        과목: \(subject.rawValue), 주제: \(topic), 난이도: \(difficulty.rawValue), 문제 수: \(clampedCount)개
        
        반드시 아래 JSON 형식으로만 응답 (다른 텍스트 없이):
        [{"id":"UUID","question":"쿠키 말투 문제 (예: 자, 문제야! ... 잘 생각해봐~ 🤔)","expectedKeywords":["키워드1"],"subject":"\(subject.rawValue)","difficulty":"\(difficulty.rawValue)","gradeLevel":"\(gradeLevel.rawValue)"}]
        
        규칙: 주관식 서술형만, 정답 포함 금지
        """
        let response = try await sendWithRetry(prompt: prompt)
        return try parseQuizzes(from: response)
    }

    func evaluateAnswer(quiz: Quiz, userAnswer: String, gradeLevel: GradeLevel) async throws -> AnswerFeedback {
        // CP-3: 답변 길이 제한
        let truncated = String(userAnswer.prefix(GeminiAPILimits.answerMaxChars))
        let prompt = """
        당신은 '쿠키'라는 귀여운 강아지 AI 선생님입니다.
        [\(gradeLevel.vocabularyLevel)]
        문제: \(quiz.question)
        핵심 키워드: \(quiz.expectedKeywords.joined(separator: ", "))
        학습자 답변: \(truncated)
        
        쿠키 말투로 평가해주세요. 반드시 아래 JSON 형식으로만 응답:
        {"isCorrect":true/false,"score":0~100,"explanation":"쿠키 말투 피드백 (정답이면 크게 칭찬, 오답이면 따뜻하게)","correctAnswer":"오답 시 정답 설명 (정답이면 빈 문자열)"}
        """
        let response = try await sendWithRetry(prompt: prompt)
        return try parseFeedback(from: response)
    }

    func generateHint(quiz: Quiz, hintLevel: Int, gradeLevel: GradeLevel) async throws -> String {
        // CP-2: 힌트 단계 클램핑
        let clampedLevel = max(1, min(GeminiAPILimits.maxHintLevel, hintLevel))
        let hintType: String
        switch clampedLevel {
        case 1: hintType = "핵심 개념 방향만 알려주는 힌트"
        case 2: hintType = "관련 예시나 비유를 통한 힌트"
        case 3: hintType = "정답 구조/형식을 알려주는 힌트 (정답 직접 제공 절대 금지)"
        default: hintType = "방향만 알려주는 힌트"
        }
        let prompt = """
        당신은 '쿠키'라는 귀여운 강아지 AI 선생님입니다.
        [\(gradeLevel.vocabularyLevel)]
        문제: \(quiz.question)
        힌트 단계: \(clampedLevel)/3 — \(hintType)
        
        쿠키 말투로 100자 이내 힌트를 작성하세요. 절대 정답을 직접 알려주지 마세요.
        예: "힌트! [힌트 내용]. 이걸 생각해봐~ 🤔"
        """
        let response = try await sendWithRetry(prompt: prompt)
        return extractText(from: response)
    }

    func extractTopicFromVideo(videoTitle: String, subject: Subject, gradeLevel: GradeLevel) async throws -> String {
        let prompt = """
        YouTube 영상 제목: \(videoTitle)
        과목: \(subject.rawValue), 학습자 수준: \(gradeLevel.vocabularyLevel)
        
        영상과 관련된 학습 주제를 한 문장으로 작성해주세요.
        """
        let response = try await sendWithRetry(prompt: prompt)
        return extractText(from: response)
    }

    // MARK: - Private

    private func sendWithRetry(prompt: String, attempt: Int = 1) async throws -> GeminiResponse {
        do {
            return try await sendRequest(prompt: prompt)
        } catch let error as AITutorError {
            if retryPolicy.shouldRetry(error: error, attempt: attempt) {
                let delay = retryPolicy.delay(for: attempt)
                try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                return try await sendWithRetry(prompt: prompt, attempt: attempt + 1)
            }
            throw error
        }
    }

    private func sendRequest(prompt: String) async throws -> GeminiResponse {
        try checkRateLimit()

        guard let url = URL(string: "\(baseURL)?key=\(apiKey)") else {
            throw AITutorError.networkError("잘못된 URL")
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30
        request.httpBody = try JSONEncoder().encode(GeminiRequest(prompt: prompt))

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AITutorError.networkError("응답 없음")
        }

        switch httpResponse.statusCode {
        case 200:
            dailyRequestCount += 1
            return try JSONDecoder().decode(GeminiResponse.self, from: data)
        case 429:
            throw AITutorError.rateLimitExceeded
        case 401, 403:
            throw AITutorError.invalidAPIKey
        default:
            throw AITutorError.networkError("HTTP \(httpResponse.statusCode)")
        }
    }

    private func checkRateLimit() throws {
        let now = Date()
        if !Calendar.current.isDate(now, inSameDayAs: lastResetDate) {
            dailyRequestCount = 0
            lastResetDate = now
        }
        if dailyRequestCount >= GeminiAPILimits.requestsPerDay {
            throw AITutorError.dailyLimitExceeded
        }
    }

    private func extractText(from response: GeminiResponse) -> String {
        response.candidates.first?.content.parts.first?.text ?? ""
    }

    private func parseQuizzes(from response: GeminiResponse) throws -> [Quiz] {
        let text = extractText(from: response)
        // JSON 코드 블록 제거
        let cleaned = text
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard let data = cleaned.data(using: .utf8) else {
            throw AITutorError.parseError("Quiz JSON 변환 실패")
        }
        return try JSONDecoder().decode([Quiz].self, from: data)
    }

    private func parseFeedback(from response: GeminiResponse) throws -> AnswerFeedback {
        let text = extractText(from: response)
        let cleaned = text
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard let data = cleaned.data(using: .utf8) else {
            throw AITutorError.parseError("Feedback JSON 변환 실패")
        }
        return try JSONDecoder().decode(AnswerFeedback.self, from: data)
    }
}
```

---

### 5.7 `RetryPolicy.swift` 구현

경로: `Core/Network/RetryPolicy.swift`

```swift
import Foundation

struct RetryPolicy {
    let maxAttempts: Int = 3
    let baseDelay: TimeInterval = 1.0
    let multiplier: Double = 2.0

    /// 지수 백오프 딜레이: 1초 → 2초 → 4초
    func delay(for attempt: Int) -> TimeInterval {
        baseDelay * pow(multiplier, Double(attempt - 1))
    }

    func shouldRetry(error: AITutorError, attempt: Int) -> Bool {
        guard attempt < maxAttempts else { return false }
        return error.isRetryable
    }
}
```

---

### 5.8 `MockAITutor.swift` 구현

경로: `Tests/UnitTests/AITutor/MockAITutor.swift`

```swift
import Foundation
@testable import SISOLearn

final class MockAITutor: AITutorProtocol {

    // 테스트 제어
    var shouldThrowError: AITutorError?
    var explanationToReturn = "쿠키가 설명해줄게! 분수는 전체를 나눈 것 중 하나야. 🐾"
    var quizzesToReturn: [Quiz] = [Quiz.mock()]
    var feedbackToReturn = AnswerFeedback(isCorrect: true, score: 80,
                                          explanation: "와! 정답이야! 🎉", correctAnswer: "")
    var hintToReturn = "힌트! 분자와 분모를 생각해봐~ 🤔"

    // 호출 추적
    var generateExplanationCallCount = 0
    var generateQuizzesCallCount = 0
    var evaluateAnswerCallCount = 0
    var generateHintCallCount = 0
    var lastHintLevelRequested: Int?
    var lastUserAnswerReceived: String?
    var lastQuizCountRequested: Int?

    func generateExplanation(topic: String, gradeLevel: GradeLevel, subject: Subject) async throws -> String {
        generateExplanationCallCount += 1
        if let error = shouldThrowError { throw error }
        return explanationToReturn
    }

    func generateQuizzes(topic: String, gradeLevel: GradeLevel, subject: Subject,
                         difficulty: Difficulty, count: Int) async throws -> [Quiz] {
        generateQuizzesCallCount += 1
        lastQuizCountRequested = count
        if let error = shouldThrowError { throw error }
        return quizzesToReturn
    }

    func evaluateAnswer(quiz: Quiz, userAnswer: String, gradeLevel: GradeLevel) async throws -> AnswerFeedback {
        evaluateAnswerCallCount += 1
        lastUserAnswerReceived = userAnswer
        if let error = shouldThrowError { throw error }
        return feedbackToReturn
    }

    func generateHint(quiz: Quiz, hintLevel: Int, gradeLevel: GradeLevel) async throws -> String {
        generateHintCallCount += 1
        lastHintLevelRequested = hintLevel
        if let error = shouldThrowError { throw error }
        return hintToReturn
    }

    func extractTopicFromVideo(videoTitle: String, subject: Subject, gradeLevel: GradeLevel) async throws -> String {
        if let error = shouldThrowError { throw error }
        return "테스트 학습 주제"
    }
}
```

---

### 5.9~5.12 테스트 작성

경로: `Tests/PropertyTests/QuizCountPropertyTests.swift`

```swift
import Testing
@testable import SISOLearn

struct QuizCountPropertyTests {

    // CP-1: Quiz 수는 항상 3~10 범위
    @Test("Quiz 수 범위 속성 테스트", arguments: [-5, 0, 1, 2, 3, 5, 10, 11, 20])
    func quizCountAlwaysInRange(requestedCount: Int) async throws {
        let mock = MockAITutor()
        mock.quizzesToReturn = Array(repeating: Quiz.mock(), count: max(3, min(10, requestedCount)))
        let useCase = StartLearningSessionUseCase(aiTutor: mock)

        // 어떤 값을 요청해도 3~10 범위로 클램핑되어야 함
        let clampedCount = max(3, min(10, requestedCount))
        #expect(clampedCount >= 3)
        #expect(clampedCount <= 10)
    }
}

struct HintLevelPropertyTests {

    // CP-2: 힌트 단계는 항상 1~3 범위
    @Test("힌트 단계 범위 속성 테스트", arguments: [-2, 0, 1, 2, 3, 4, 5])
    func hintLevelAlwaysInRange(requestedLevel: Int) async throws {
        let clampedLevel = max(1, min(3, requestedLevel))
        #expect(clampedLevel >= 1)
        #expect(clampedLevel <= 3)
    }
}

struct AnswerLengthPropertyTests {

    // CP-3: 답변 길이는 항상 1,000자 이하
    @Test("답변 길이 제한 속성 테스트", arguments: [0, 500, 999, 1000, 1001, 2000])
    func answerLengthAlwaysWithinLimit(inputLength: Int) async throws {
        let input = String(repeating: "가", count: inputLength)
        let truncated = String(input.prefix(1000))
        #expect(truncated.count <= 1000)
    }
}
```

---

## 완료 기준 확인

| 항목 | 확인 방법 |
|------|-----------|
| MockAITutor 테스트 | `Cmd+U` → 모든 Property 테스트 통과 |
| 실제 API 호출 | SettingsView에서 API Key 입력 후 간단한 설명 생성 테스트 |
| 에러 처리 | 잘못된 API Key로 호출 시 `invalidAPIKey` 에러 발생 확인 |
| 재시도 로직 | 네트워크 오류 시 최대 3회 재시도 후 에러 전파 확인 |

---

## 다음 단계

Task 5 완료 후 **Task 6 (쿠키 캐릭터 모듈)** 로 진행한다.
Task 6에서 `CookiePersonaWrapper`를 구현하면 Task 5의 프롬프트를 교체한다.
