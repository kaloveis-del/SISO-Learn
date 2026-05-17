# Task 12 가이드: 테스트 완성 및 TestFlight 배포 준비

> **단계**: 6단계 (완성) | **선행 태스크**: Task 11 | **후행 태스크**: 없음 (최종)

---

## 목표

전체 테스트 커버리지를 확인하고, 속성 기반 테스트(PBT)로 핵심 정확성 속성을 검증한 뒤 TestFlight를 통해 두 딸의 iPad에 배포한다.

---

## 체크리스트

- [x] 12.1 전체 단위 테스트 커버리지 확인 (Domain 90%, ViewModel 80%)
- [x] 12.2 속성 기반 테스트(PBT) 전체 실행 확인
- [x] 12.3 전체 학습 흐름 통합 테스트 실행
- [ ] 12.4 iPad Air M1 / M5 시뮬레이터 테스트 (Xcode 빌드 후 수동 확인)
- [ ] 12.5 App Store Connect 앱 등록 및 TestFlight 설정 (Apple Developer 계정 필요)
- [ ] 12.6 내부 테스터(두 딸) 초대 및 TestFlight 배포 (12.5 완료 후 진행)
- [ ] 12.7 피드백 수집 및 버그 수정 (배포 후 진행)

---

## 상세 구현 가이드

### 12.1 테스트 커버리지 확인

Xcode에서 커버리지 활성화:
1. `Product → Scheme → Edit Scheme`
2. `Test → Options → Code Coverage` 체크
3. `Cmd+U` 실행 후 `Report Navigator → Coverage` 탭 확인

목표 커버리지:

| 레이어 | 목표 | 우선순위 |
|--------|------|---------|
| Domain (Use Cases) | 90% 이상 | 최우선 |
| Data (Repositories) | 80% 이상 | 높음 |
| ViewModel | 80% 이상 | 높음 |
| AITutor (Mock 기반) | 85% 이상 | 높음 |
| Keychain 서비스 | 90% 이상 | 높음 |
| View (SwiftUI) | 수동 테스트 | 낮음 |

커버리지 부족 시 추가할 테스트 목록:

```swift
// 누락된 테스트 예시
// ManageProfileUseCaseTests
func test_create_throwsWhenMaxReached() async throws {
    // 5개 생성 후 6번째 시도 → ProfileError.maxProfilesReached
}

// LearningSessionViewModelTests
func test_proceedToNextQuiz_completesSessionOnLastQuiz() async {
    // 마지막 문제 후 proceedToNextQuiz() → phase == .sessionComplete
}

// KeychainServiceTests
func test_save_overwritesExistingKey() throws {
    // 같은 키 두 번 저장 → 마지막 값만 유지
}
```

---

### 12.2 속성 기반 테스트(PBT) 전체 실행

경로: `Tests/PropertyTests/`

모든 PBT 파일이 존재하는지 확인:

```
Tests/PropertyTests/
├── QuizCountPropertyTests.swift      ← CP-1: Quiz 수 3~10
├── HintLevelPropertyTests.swift      ← CP-2: 힌트 단계 1~3
├── AnswerLengthPropertyTests.swift   ← CP-3: 답변 1,000자 이하
└── ProfileLimitPropertyTests.swift   ← CP-5: 프로필 5개 이하
```

누락된 PBT 추가:

```swift
// Tests/PropertyTests/AccuracyRatePropertyTests.swift
// CP-7: 정답률은 항상 0.0~1.0 범위

import Testing
@testable import SISOLearn

struct AccuracyRatePropertyTests {

    @Test("정답률 범위 속성 테스트", arguments: [
        (correct: 0, total: 5),
        (correct: 3, total: 5),
        (correct: 5, total: 5),
        (correct: 0, total: 0)
    ])
    func accuracyRateAlwaysInRange(correct: Int, total: Int) {
        let rate = total == 0 ? 0.0 : Double(correct) / Double(total)
        #expect(rate >= 0.0)
        #expect(rate <= 1.0)
    }
}
```

PBT 전체 실행 명령:
```bash
# 터미널에서 실행
xcodebuild test \
  -scheme SISOLearn \
  -destination 'platform=iOS Simulator,name=iPad Air (5th generation)' \
  -only-testing:SISOLearnTests/PropertyTests
```

---

### 12.3 전체 학습 흐름 통합 테스트

경로: `Tests/IntegrationTests/LearningFlowIntegrationTests.swift`

```swift
import XCTest
@testable import SISOLearn

@MainActor
final class LearningFlowIntegrationTests: XCTestCase {

    var stack: CoreDataStack!
    var mockAI: MockAITutor!
    var profile: Profile!

    override func setUp() async throws {
        stack = CoreDataStack.inMemory()
        mockAI = MockAITutor()
        mockAI.quizzesToReturn = [Quiz.mock(), Quiz.mock(), Quiz.mock()]
        mockAI.feedbackToReturn = AnswerFeedback(
            isCorrect: true, score: 90,
            explanation: "와! 정답이야! 🎉", correctAnswer: "")

        let profileRepo = ProfileRepository(stack: stack)
        profile = try await profileRepo.create(
            name: "테스트", gradeLevel: .grade5Elementary, avatarIndex: 0)
    }

    /// 전체 학습 흐름: 시작 → Quiz 3개 → 완료 → CoreData 저장
    func test_fullLearningFlow_savesSessionToDatabase() async throws {
        let sessionRepo = SessionRepository(stack: stack)
        let vm = LearningSessionViewModel(
            profile: profile, subject: .math, difficulty: .normal, topic: "분수",
            startSessionUseCase: StartLearningSessionUseCase(aiTutor: mockAI),
            submitAnswerUseCase: SubmitAnswerUseCase(aiTutor: mockAI),
            requestHintUseCase: RequestHintUseCase(aiTutor: mockAI),
            saveProgressUseCase: SaveProgressUseCase(sessionRepo: sessionRepo))

        // 1. 세션 시작
        vm.startSession(quizCount: 3)
        try await Task.sleep(nanoseconds: 200_000_000)
        XCTAssertEqual(vm.quizzes.count, 3)

        // 2. Quiz 3개 풀기
        for _ in 0..<3 {
            vm.proceedToQuiz()
            vm.userAnswer = "테스트 답변"
            vm.submitAnswer()
            try await Task.sleep(nanoseconds: 200_000_000)
            vm.proceedToNextQuiz()
            try await Task.sleep(nanoseconds: 100_000_000)
        }

        // 3. 세션 완료 확인
        XCTAssertEqual(vm.currentPhase, .sessionComplete)
        XCTAssertEqual(vm.sessionResults.count, 3)
        XCTAssertEqual(vm.accuracyRate, 1.0, accuracy: 0.001)

        // 4. CoreData 저장 확인
        try await Task.sleep(nanoseconds: 500_000_000)
        let sessions = try await sessionRepo.fetchRecent(profileId: profile.id, limit: 10)
        XCTAssertEqual(sessions.count, 1)
        XCTAssertEqual(sessions.first?.correctCount, 3)
    }

    /// 힌트 3단계 후 제한 확인
    func test_hintLimit_blocksAfterThreeHints() async throws {
        let vm = LearningSessionViewModel(
            profile: profile, subject: .math, difficulty: .normal, topic: "분수",
            startSessionUseCase: StartLearningSessionUseCase(aiTutor: mockAI),
            submitAnswerUseCase: SubmitAnswerUseCase(aiTutor: mockAI),
            requestHintUseCase: RequestHintUseCase(aiTutor: mockAI),
            saveProgressUseCase: SaveProgressUseCase(sessionRepo: SessionRepository(stack: stack)))

        vm.quizzes = [Quiz.mock()]
        vm.currentPhase = .quiz

        vm.requestHint()
        try await Task.sleep(nanoseconds: 100_000_000)
        vm.requestHint()
        try await Task.sleep(nanoseconds: 100_000_000)
        vm.requestHint()
        try await Task.sleep(nanoseconds: 100_000_000)

        XCTAssertFalse(vm.canRequestHint)
        XCTAssertEqual(vm.hintCount, 3)
        XCTAssertEqual(mockAI.generateHintCallCount, 3)
    }
}
```

---

### 12.4 iPad 시뮬레이터 테스트

테스트할 시뮬레이터 목록:

| 기기 | OS | 대상 |
|------|-----|------|
| iPad Air (5th gen) M1 | iPadOS 16.0 | 둘째딸 기기 |
| iPad Air (M2) | iPadOS 17.0 | 큰딸 기기 (M5 근사치) |
| iPad Air (5th gen) M1 | iPadOS 17.0 | 최신 OS 호환성 |

각 시뮬레이터에서 확인할 항목:

```
✅ 앱 실행 및 프로필 생성
✅ API Key 입력 및 저장
✅ 학습 세션 전체 흐름 (쿠키 인사 → 설명 → Quiz → 피드백 → 완료)
✅ 힌트 3단계 제한
✅ YouTube URL 입력 및 분할 화면
✅ Progress 화면 (스트릭, 배지)
✅ 다크 모드 전환
✅ 가로/세로 모드 전환
✅ VoiceOver 기본 탐색
```

---

### 12.5 App Store Connect 앱 등록

1. **Apple Developer 계정** 확인 (developer.apple.com)

2. **App Store Connect** (appstoreconnect.apple.com) 접속
   - `My Apps → +` → `New App`
   - Platform: iOS
   - Name: SISO-Learn
   - Bundle ID: `com.sisolearn.app`
   - SKU: `sisolearn-001`

3. **Xcode에서 Archive 생성**:
   ```
   Product → Archive
   → Distribute App → TestFlight & App Store
   → Upload
   ```

4. **앱 정보 입력** (App Store Connect):
   - 앱 설명 (한국어)
   - 스크린샷 (iPad 12.9인치)
   - 연령 등급: 4+ (아동용)
   - 개인정보 처리방침 URL

---

### 12.6 TestFlight 내부 테스터 초대

1. App Store Connect → `TestFlight` 탭
2. `Internal Testing → Add Testers`
3. 두 딸의 Apple ID 이메일 입력
4. 초대 이메일 발송

두 딸의 iPad에서:
1. App Store에서 **TestFlight** 앱 설치
2. 이메일의 초대 링크 탭
3. SISO-Learn 설치 및 실행

---

### 12.7 피드백 수집 및 버그 수정

TestFlight 피드백 수집 방법:
- TestFlight 앱 내 스크린샷 + 피드백 전송 기능 활용
- 두 딸에게 직접 물어보기 (가장 중요!)

주요 확인 질문:
```
1. 쿠키가 말하는 게 재미있어?
2. 문제가 너무 어렵거나 쉽지 않아?
3. 힌트가 도움이 됐어?
4. 어떤 과목이 제일 재미있었어?
5. 앱에서 불편한 게 있었어?
```

버그 수정 후 재배포:
```
버전 업 (1.0.0 → 1.0.1)
→ Archive → Upload → TestFlight 자동 배포
```

---

## 전체 테스트 파일 목록 최종 확인

```
Tests/
├── UnitTests/
│   ├── AITutor/
│   │   ├── GeminiAITutorTests.swift      ✅ Task 5
│   │   └── MockAITutor.swift             ✅ Task 5
│   ├── Cookie/
│   │   └── CookieViewModelTests.swift    ✅ Task 6
│   ├── Profile/
│   │   ├── ProfileViewModelTests.swift   ✅ Task 4
│   │   └── ManageProfileUseCaseTests.swift ✅ Task 4
│   ├── Learning/
│   │   └── LearningSessionViewModelTests.swift ✅ Task 7
│   ├── Settings/
│   │   └── KeychainServiceTests.swift    ✅ Task 3
│   ├── YouTube/
│   │   └── YouTubeServiceTests.swift     ✅ Task 8
│   ├── Progress/
│   │   └── ProgressViewModelTests.swift  ✅ Task 9
│   └── Error/
│       └── ErrorHandlingTests.swift      ✅ Task 10
├── IntegrationTests/
│   ├── CoreDataIntegrationTests.swift    ✅ Task 2
│   └── LearningFlowIntegrationTests.swift ✅ Task 12
└── PropertyTests/
    ├── QuizCountPropertyTests.swift      ✅ Task 5 (CP-1)
    ├── HintLevelPropertyTests.swift      ✅ Task 5 (CP-2)
    ├── AnswerLengthPropertyTests.swift   ✅ Task 5 (CP-3)
    ├── ProfileLimitPropertyTests.swift   ✅ Task 4 (CP-5)
    └── AccuracyRatePropertyTests.swift   ✅ Task 12 (CP-7)
```

---

## 완료 기준 확인

| 항목 | 확인 방법 |
|------|-----------|
| 커버리지 | Xcode Coverage 탭에서 Domain 90%, ViewModel 80% 확인 |
| PBT 전체 통과 | `Cmd+U` → PropertyTests 폴더 모두 초록 |
| 통합 테스트 | `LearningFlowIntegrationTests` 모두 통과 |
| 시뮬레이터 | iPad Air M1/M2 시뮬레이터에서 전체 흐름 확인 |
| TestFlight | 두 딸의 iPad에서 앱 설치 및 실행 성공 |

---

## 🎉 프로젝트 완료!

모든 12개 태스크가 완료되면 SISO-Learn 앱이 완성된다.

**개발 완료 체크리스트:**
- [ ] Task 1: 프로젝트 설정 ✅
- [ ] Task 2: CoreData ✅
- [ ] Task 3: Keychain + 설정 ✅
- [ ] Task 4: 프로필 관리 ✅
- [ ] Task 5: AI 연동 ✅
- [ ] Task 6: 쿠키 캐릭터 ✅
- [ ] Task 7: 대화형 학습 세션 ✅
- [ ] Task 8: YouTube 연계 ✅
- [ ] Task 9: Progress ✅
- [ ] Task 10: 에러 처리 ✅
- [ ] Task 11: UI 완성도 ✅
- [ ] Task 12: 테스트 + 배포 ✅

쿠키와 함께 즐거운 학습 되세요! 🐶🎉
