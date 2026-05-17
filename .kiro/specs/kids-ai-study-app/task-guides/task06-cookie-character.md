# Task 6 가이드: 쿠키 캐릭터 모듈 구현

> **단계**: 3단계 (쿠키 캐릭터) | **선행 태스크**: Task 5 | **후행 태스크**: Task 7

---

## 목표

앱의 핵심 UX인 강아지 캐릭터 **쿠키(Cookie)** 🐶를 구현한다. 쿠키는 5가지 감정 상태를 가지며, 학습 단계에 따라 자동으로 감정과 메시지가 전환된다. 모든 AI 응답은 쿠키의 말투로 래핑된다.

---

## 체크리스트

- [x] 6.1 쿠키 이미지 에셋 추가
- [x] 6.2 `CookieEmotion.swift` 구현
- [x] 6.3 `CookieMessageTemplates.swift` 구현
- [x] 6.4 `CookiePersonaWrapper.swift` 구현
- [x] 6.5 `CookieViewModel.swift` 구현
- [x] 6.6 `BubbleTailShape.swift` 구현
- [x] 6.7 `CookieBubbleView.swift` 구현
- [x] 6.8 `CookieCharacterView.swift` 구현
- [x] 6.9 쿠키 모듈 테스트 작성

---

## 상세 구현 가이드

### 6.1 쿠키 이미지 에셋 추가

`Assets.xcassets`에 `Cookie` 폴더를 만들고 5종 이미지를 추가한다.

| 파일명 | 감정 | 사용 시점 |
|--------|------|-----------|
| `cookie_normal` | 기본 😊 | 대기, 답변 입력 중 |
| `cookie_excited` | 신남 🐾 | 인사, 학습 시작, 설명 |
| `cookie_praising` | 칭찬 🎉 | 정답, 세션 완료 |
| `cookie_thinking` | 고민 🤔 | Quiz 출제, 힌트 |
| `cookie_comforting` | 위로 🥺 | 오답, 에러 |

> 💡 **이미지 없을 때 임시 방법**: SF Symbols 또는 이모지를 사용한다.
> 실제 강아지 일러스트는 나중에 교체 가능하도록 `Image("cookie_\(emotion.rawValue)")` 형태로 구현한다.

---

### 6.2 `CookieEmotion.swift` 구현

경로: `Modules/Cookie/Domain/Entities/CookieEmotion.swift`

```swift
import Foundation

enum CookieEmotion: String, CaseIterable {
    case normal     = "normal"      // 기본 대기 😊
    case excited    = "excited"     // 신남, 학습 시작 🐾
    case praising   = "praising"    // 칭찬, 정답 🎉
    case thinking   = "thinking"    // 고민, Quiz 출제 🤔
    case comforting = "comforting"  // 위로, 오답 🥺

    var emoji: String {
        switch self {
        case .normal:     return "😊"
        case .excited:    return "🐾"
        case .praising:   return "🎉"
        case .thinking:   return "🤔"
        case .comforting: return "🥺"
        }
    }

    /// 학습 단계에 따른 자동 감정 매핑
    static func from(phase: LearningPhase, isCorrect: Bool? = nil) -> CookieEmotion {
        switch phase {
        case .greeting:         return .excited
        case .explanation:      return .excited
        case .quiz:             return .thinking
        case .answering:        return .normal
        case .hintRequested:    return .thinking
        case .feedback:
            guard let correct = isCorrect else { return .normal }
            return correct ? .praising : .comforting
        case .sessionComplete:  return .praising
        }
    }
}

/// 학습 단계 열거형 (LearningSessionViewModel과 공유)
enum LearningPhase: Equatable {
    case greeting           // 쿠키 인사
    case explanation        // 쿠키 설명
    case quiz               // 쿠키 문제 출제
    case answering          // 답변 입력 중
    case hintRequested(Int) // 힌트 표시 (단계)
    case feedback           // 쿠키 피드백
    case sessionComplete    // 세션 완료

    static func == (lhs: LearningPhase, rhs: LearningPhase) -> Bool {
        switch (lhs, rhs) {
        case (.greeting, .greeting),
             (.explanation, .explanation),
             (.quiz, .quiz),
             (.answering, .answering),
             (.feedback, .feedback),
             (.sessionComplete, .sessionComplete): return true
        case (.hintRequested(let a), .hintRequested(let b)): return a == b
        default: return false
        }
    }
}
```

---

### 6.3 `CookieMessageTemplates.swift` 구현

경로: `Modules/Cookie/Data/CookieMessageTemplates.swift`

```swift
import Foundation

enum CookieMessageTemplates {

    static let greetings = [
        "안녕! 나는 쿠키야 🐶 오늘도 같이 공부해볼까? 멍멍!",
        "왈왈! 쿠키야! 오늘 공부 준비됐어? 같이 해보자!",
        "안녕 친구! 쿠키가 기다리고 있었어~ 오늘 뭐 배울까? 🐾"
    ]

    static let subjectPrompts = [
        "오늘은 어떤 걸 공부하고 싶어? 쿠키가 도와줄게!",
        "어떤 과목이 제일 재미있어? 같이 해보자! 🐾",
        "오늘의 공부 주제를 골라봐! 쿠키가 설명해줄게~"
    ]

    static let waitingMessages = [
        "천천히 생각해도 돼. 쿠키가 기다릴게! 🐶",
        "잘 생각해봐~ 쿠키는 여기 있어!",
        "어렵지? 천천히 해봐. 쿠키가 응원해! 🐾"
    ]

    static let beforeHint = [
        "힌트가 필요해? 알겠어, 살짝만 알려줄게~ (정답은 비밀이야!)",
        "쿠키가 작은 힌트를 줄게! 잘 들어봐 🤔",
        "힌트 나간다! 이걸 보고 다시 생각해봐~"
    ]

    static let correctResponses = [
        "와아! 정답이야! 역시 최고야! 🎉 멍멍!",
        "맞았어! 쿠키가 너무 기뻐! 🎉🐾",
        "정답! 정말 잘했어! 쿠키가 자랑스러워~ 🎉"
    ]

    static let incorrectResponses = [
        "아, 아쉽다~ 괜찮아! 같이 다시 생각해보자! 🥺",
        "틀렸지만 괜찮아! 이렇게 생각하면 돼. 쿠키가 설명해줄게 🥺",
        "아쉽네~ 하지만 포기하지 마! 쿠키가 도와줄게! 🥺"
    ]

    static let sessionComplete = [
        "오늘 공부 끝! 정말 열심히 했어. 쿠키가 자랑스러워! 🐾🎉",
        "와! 다 끝났어! 오늘도 최고였어! 멍멍! 🎉",
        "수고했어! 오늘 공부 정말 잘했어. 내일도 같이 하자! 🐶🎉"
    ]

    static let offlineMessages = [
        "인터넷이 없어서 쿠키가 대답을 못 하겠어 🥺 연결 확인해줘!",
        "앗, 인터넷이 끊겼어! 연결되면 다시 공부하자 🥺"
    ]

    static let rateLimitMessages = [
        "쿠키가 잠깐 쉬어야 해~ 1분 후에 다시 해보자! 🐶",
        "조금만 기다려줘! 쿠키가 금방 돌아올게 🐾"
    ]

    static func random(from pool: [String]) -> String {
        pool.randomElement() ?? pool[0]
    }
}
```

---

### 6.4 `CookiePersonaWrapper.swift` 구현

경로: `Modules/Cookie/Data/CookiePersonaWrapper.swift`

```swift
import Foundation

/// AI 프롬프트에 쿠키 페르소나를 주입하는 래퍼
/// Task 5의 GeminiAITutor에서 이 래퍼를 사용하도록 교체한다
enum CookiePersonaWrapper {

    static func systemPrompt(gradeLevel: GradeLevel) -> String {
        """
        당신은 '쿠키'라는 이름의 귀여운 강아지 AI 선생님입니다.

        [쿠키의 성격]
        - 항상 친근하고 따뜻하게 말함
        - 가끔 "멍멍!", "왈왈!", "🐶", "🐾" 같은 강아지 표현 사용 (문장당 최대 1회)
        - 어렵거나 틀려도 절대 혼내지 않고 응원함
        - 정답을 맞추면 크게 칭찬함

        [학습자 수준] \(gradeLevel.vocabularyLevel)

        [말투 규칙]
        - \(gradeLevel == .grade5Elementary ? "초등학생에게 말하듯 쉽고 친근하게" : "중학생에게 말하듯 조금 더 성숙하게, 하지만 여전히 친근하게")
        - 문장은 짧고 명확하게
        - 강아지 이모지는 문장 끝에만 사용
        """
    }

    static func explanationPrompt(topic: String, gradeLevel: GradeLevel, subject: Subject) -> String {
        """
        \(systemPrompt(gradeLevel: gradeLevel))

        [과목] \(subject.rawValue)
        [주제] \(topic)

        쿠키가 위 주제를 학습자에게 설명해주세요.
        - 반드시 500자 이내
        - 쉬운 예시 1개 포함
        - 마지막에 "이제 문제를 풀어볼까? 🤔" 로 마무리
        - 쿠키의 말투로 자연스럽게 작성
        """
    }

    static func quizPrompt(topic: String, gradeLevel: GradeLevel, subject: Subject,
                           difficulty: Difficulty, count: Int) -> String {
        """
        \(systemPrompt(gradeLevel: gradeLevel))

        [과목] \(subject.rawValue) | [주제] \(topic) | [난이도] \(difficulty.rawValue) | [문제 수] \(count)개

        쿠키가 출제하는 Quiz를 JSON 배열로 생성해주세요.
        각 문제의 "question" 필드는 쿠키의 말투로 작성하세요.
        예: "자, 문제야! [문제 내용] 잘 생각해봐~ 🤔"

        반드시 아래 JSON 형식으로만 응답 (다른 텍스트 없이):
        [{"id":"UUID","question":"쿠키 말투의 문제","expectedKeywords":["키워드1","키워드2"],"subject":"\(subject.rawValue)","difficulty":"\(difficulty.rawValue)","gradeLevel":"\(gradeLevel.rawValue)"}]

        규칙: 주관식 서술형만, 정답 포함 금지
        """
    }

    static func feedbackPrompt(quiz: Quiz, userAnswer: String, gradeLevel: GradeLevel) -> String {
        """
        \(systemPrompt(gradeLevel: gradeLevel))

        [문제] \(quiz.question)
        [핵심 키워드] \(quiz.expectedKeywords.joined(separator: ", "))
        [학습자 답변] \(userAnswer)

        쿠키가 학습자의 답변을 평가하고 피드백을 줍니다.
        반드시 아래 JSON 형식으로만 응답:
        {"isCorrect":true/false,"score":0~100,"explanation":"쿠키 말투의 피드백 (200자 이내, 정답이면 크게 칭찬, 오답이면 따뜻하게 설명)","correctAnswer":"오답 시 정답 설명 (정답이면 빈 문자열)"}
        """
    }

    static func hintPrompt(quiz: Quiz, hintLevel: Int, gradeLevel: GradeLevel) -> String {
        let hintType: String
        switch hintLevel {
        case 1: hintType = "핵심 개념 방향만 알려주는 힌트"
        case 2: hintType = "관련 예시나 비유를 통한 힌트"
        case 3: hintType = "정답 구조/형식을 알려주는 힌트 (정답 직접 제공 절대 금지)"
        default: hintType = "방향만 알려주는 힌트"
        }

        return """
        \(systemPrompt(gradeLevel: gradeLevel))

        [문제] \(quiz.question)
        [힌트 단계] \(hintLevel)/3단계 — \(hintType)

        쿠키가 힌트를 줍니다. 100자 이내로, 쿠키 말투로 작성하세요.
        절대로 정답을 직접 알려주지 마세요.
        예: "힌트! [힌트 내용]. 이걸 생각해봐~ 🤔"
        """
    }
}
```

> ✅ **Task 5 연동**: `GeminiAITutor`의 각 메서드에서 직접 작성한 프롬프트를 `CookiePersonaWrapper`의 메서드로 교체한다.

---

### 6.5 `CookieViewModel.swift` 구현

경로: `Modules/Cookie/Presentation/ViewModels/CookieViewModel.swift`

```swift
import SwiftUI

@MainActor
final class CookieViewModel: ObservableObject {

    @Published var currentMessage: String = ""
    @Published var currentEmotion: CookieEmotion = .normal
    @Published var isTyping: Bool = false

    /// 쿠키 메시지 업데이트 (타이핑 효과 포함)
    func speak(_ message: String, emotion: CookieEmotion, animated: Bool = true) {
        currentEmotion = emotion
        if animated {
            isTyping = true
            Task {
                try? await Task.sleep(nanoseconds: 500_000_000) // 0.5초 타이핑 인디케이터
                currentMessage = message
                isTyping = false
            }
        } else {
            currentMessage = message
            isTyping = false
        }
    }

    /// 학습 단계 변경 시 자동 메시지/감정 설정
    func updateForPhase(_ phase: LearningPhase, isCorrect: Bool? = nil, userName: String = "") {
        let emotion = CookieEmotion.from(phase: phase, isCorrect: isCorrect)
        let message: String

        switch phase {
        case .greeting:
            message = CookieMessageTemplates.random(from: CookieMessageTemplates.greetings)
        case .explanation:
            message = CookieMessageTemplates.random(from: CookieMessageTemplates.subjectPrompts)
        case .quiz:
            message = CookieMessageTemplates.random(from: CookieMessageTemplates.waitingMessages)
        case .answering:
            message = CookieMessageTemplates.random(from: CookieMessageTemplates.waitingMessages)
        case .hintRequested:
            message = CookieMessageTemplates.random(from: CookieMessageTemplates.beforeHint)
        case .feedback:
            if let correct = isCorrect {
                message = correct
                    ? CookieMessageTemplates.random(from: CookieMessageTemplates.correctResponses)
                    : CookieMessageTemplates.random(from: CookieMessageTemplates.incorrectResponses)
            } else {
                message = ""
            }
        case .sessionComplete:
            let base = CookieMessageTemplates.random(from: CookieMessageTemplates.sessionComplete)
            message = userName.isEmpty ? base : base.replacingOccurrences(of: "정말", with: "\(userName) 정말")
        }

        speak(message, emotion: emotion)
    }

    /// AI 생성 메시지를 쿠키 말풍선으로 표시
    func speakAIMessage(_ message: String, phase: LearningPhase) {
        let emotion = CookieEmotion.from(phase: phase)
        speak(message, emotion: emotion)
    }

    /// 에러 메시지 표시
    func speakError(_ error: AITutorError) {
        let message: String
        switch error {
        case .offline:
            message = CookieMessageTemplates.random(from: CookieMessageTemplates.offlineMessages)
        case .rateLimitExceeded:
            message = CookieMessageTemplates.random(from: CookieMessageTemplates.rateLimitMessages)
        default:
            message = error.errorDescription ?? "오류가 생겼어요. 다시 시도해봐! 🥺"
        }
        speak(message, emotion: .comforting)
    }
}
```

---

### 6.6 `BubbleTailShape.swift` 구현

경로: `Modules/Cookie/Presentation/Views/BubbleTailShape.swift`

```swift
import SwiftUI

/// 말풍선 좌하단 꼬리 모양 Shape
struct BubbleTailShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}
```

---

### 6.7 `CookieBubbleView.swift` 구현

경로: `Modules/Cookie/Presentation/Views/CookieBubbleView.swift`

```swift
import SwiftUI

struct CookieBubbleView: View {

    @ObservedObject var cookieVM: CookieViewModel

    var body: some View {
        HStack(alignment: .bottom, spacing: 12) {
            // 쿠키 캐릭터 이미지
            cookieCharacter

            // 말풍선
            if cookieVM.isTyping {
                typingIndicator
            } else if !cookieVM.currentMessage.isEmpty {
                messageBubble
            }

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .animation(.easeInOut(duration: 0.3), value: cookieVM.currentMessage)
        .animation(.easeInOut(duration: 0.2), value: cookieVM.isTyping)
    }

    // MARK: - 쿠키 캐릭터
    private var cookieCharacter: some View {
        ZStack {
            Circle()
                .fill(Color.orange.opacity(0.15))
                .frame(width: 72, height: 72)

            // 이미지 에셋이 있으면 Image("cookie_\(cookieVM.currentEmotion.rawValue)")로 교체
            Text(cookieVM.currentEmotion.emoji)
                .font(.system(size: 40))
        }
        .scaleEffect(cookieVM.isTyping ? 1.05 : 1.0)
        .animation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true),
                   value: cookieVM.isTyping)
    }

    // MARK: - 타이핑 인디케이터
    private var typingIndicator: some View {
        HStack(spacing: 4) {
            ForEach(0..<3) { index in
                Circle()
                    .fill(Color.orange)
                    .frame(width: 8, height: 8)
                    .scaleEffect(cookieVM.isTyping ? 1.2 : 0.8)
                    .animation(
                        .easeInOut(duration: 0.4)
                            .repeatForever()
                            .delay(Double(index) * 0.15),
                        value: cookieVM.isTyping
                    )
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 2)
        )
    }

    // MARK: - 메시지 말풍선
    private var messageBubble: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("쿠키 🐶")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.orange)

            ZStack(alignment: .bottomLeading) {
                Text(cookieVM.currentMessage)
                    .font(.body)
                    .foregroundColor(.primary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 18)
                            .fill(Color(.systemBackground))
                            .shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 2)
                    )

                BubbleTailShape()
                    .fill(Color(.systemBackground))
                    .frame(width: 16, height: 12)
                    .offset(x: -8, y: 0)
            }
        }
        .accessibilityLabel("쿠키: \(cookieVM.currentMessage)")
    }
}
```

---

### 6.8 `CookieCharacterView.swift` 구현

경로: `Modules/Cookie/Presentation/Views/CookieCharacterView.swift`

```swift
import SwiftUI

/// 홈 화면 등에서 쿠키 캐릭터만 단독으로 표시하는 뷰
struct CookieCharacterView: View {

    let emotion: CookieEmotion
    @State private var isAnimating = false

    var body: some View {
        ZStack {
            Circle()
                .fill(Color.orange.opacity(0.1))
                .frame(width: 120, height: 120)

            // 이미지 에셋 있으면 교체
            Text(emotion.emoji)
                .font(.system(size: 72))
        }
        .scaleEffect(isAnimating ? 1.05 : 0.95)
        .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true),
                   value: isAnimating)
        .onAppear { isAnimating = true }
        .accessibilityLabel("쿠키 캐릭터")
        .accessibilityHidden(true) // 장식용 이미지
    }
}
```

---

### 6.9 쿠키 모듈 테스트 작성

경로: `Tests/UnitTests/Cookie/CookieViewModelTests.swift`

```swift
import XCTest
@testable import SISOLearn

@MainActor
final class CookieViewModelTests: XCTestCase {

    var sut: CookieViewModel!

    override func setUp() {
        super.setUp()
        sut = CookieViewModel()
    }

    func test_speak_updatesMessageAndEmotion() async {
        sut.speak("테스트 메시지", emotion: .praising, animated: false)
        XCTAssertEqual(sut.currentMessage, "테스트 메시지")
        XCTAssertEqual(sut.currentEmotion, .praising)
        XCTAssertFalse(sut.isTyping)
    }

    func test_updateForPhase_greeting_setsExcitedEmotion() {
        sut.updateForPhase(.greeting)
        // 타이핑 인디케이터 후 감정 설정
        XCTAssertEqual(sut.currentEmotion, .excited)
    }

    func test_updateForPhase_feedback_correctSetsProising() {
        sut.updateForPhase(.feedback, isCorrect: true)
        XCTAssertEqual(sut.currentEmotion, .praising)
    }

    func test_updateForPhase_feedback_incorrectSetsComforting() {
        sut.updateForPhase(.feedback, isCorrect: false)
        XCTAssertEqual(sut.currentEmotion, .comforting)
    }

    func test_emotionFrom_phase_mapping() {
        XCTAssertEqual(CookieEmotion.from(phase: .greeting), .excited)
        XCTAssertEqual(CookieEmotion.from(phase: .quiz), .thinking)
        XCTAssertEqual(CookieEmotion.from(phase: .feedback, isCorrect: true), .praising)
        XCTAssertEqual(CookieEmotion.from(phase: .feedback, isCorrect: false), .comforting)
        XCTAssertEqual(CookieEmotion.from(phase: .sessionComplete), .praising)
    }
}
```

---

## GeminiAITutor 프롬프트 교체 (Task 5 연동)

Task 6 완료 후 `GeminiAITutor.swift`의 각 메서드 프롬프트를 교체한다:

```swift
// Before (Task 5에서 작성한 임시 프롬프트)
let prompt = "당신은 '쿠키'라는 귀여운 강아지 AI 선생님입니다. ..."

// After (CookiePersonaWrapper 사용)
let prompt = CookiePersonaWrapper.explanationPrompt(topic: topic, gradeLevel: gradeLevel, subject: subject)
let prompt = CookiePersonaWrapper.quizPrompt(topic: topic, gradeLevel: gradeLevel, subject: subject, difficulty: difficulty, count: clampedCount)
let prompt = CookiePersonaWrapper.feedbackPrompt(quiz: quiz, userAnswer: truncated, gradeLevel: gradeLevel)
let prompt = CookiePersonaWrapper.hintPrompt(quiz: quiz, hintLevel: clampedLevel, gradeLevel: gradeLevel)
```

---

## 완료 기준 확인

| 항목 | 확인 방법 |
|------|-----------|
| 쿠키 표시 | 홈 화면에서 쿠키 캐릭터와 말풍선 표시 확인 |
| 감정 전환 | 각 학습 단계별 이모지/이미지 전환 확인 |
| 타이핑 인디케이터 | 메시지 표시 전 0.5초 점 3개 애니메이션 확인 |
| 단위 테스트 | `CookieViewModelTests` 모두 통과 |

---

## 다음 단계

Task 6 완료 후 **Task 7 (대화형 학습 세션)** 로 진행한다.
Task 7에서 `LearningSessionViewModel`이 `CookieViewModel`을 연동한다.
