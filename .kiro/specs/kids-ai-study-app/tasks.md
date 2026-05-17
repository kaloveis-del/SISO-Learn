# Implementation Plan: SISO-Learn — kids-ai-study-app

## Overview

쿠키(강아지 캐릭터) AI 선생님과 함께하는 iPad 기반 인터랙티브 학습 앱 구현 계획.
개발 순서: 1단계(기반) → 2단계(AI 연동) → 3단계(쿠키 캐릭터) → 4단계(학습 세션) → 5단계(확장) → 6단계(완성)

## Tasks

- [x] 1. Task 1: Xcode 프로젝트 초기 설정 및 아키텍처 기반 구성
  - [x] 1.1 Xcode 프로젝트 생성 (SwiftUI, iPadOS 16.0 타겟, Bundle ID: com.sisolearn.app)
  - [x] 1.2 GitHub 원격 저장소 연결 및 초기 커밋
  - [x] 1.3 폴더 구조 생성 (`App/`, `Modules/`, `Core/`, `Tests/`)
  - [x] 1.4 `AppConstants.swift` 생성 (GeminiAPILimits, 앱 전역 상수 정의)
  - [x] 1.5 `String+Extensions.swift`, `Date+Extensions.swift` 생성
  - [x] 1.6 `NetworkMonitor.swift` 구현 (NWPathMonitor 기반 네트워크 상태 감지)
  - [x] 1.7 `AppDependencyContainer.swift` 구현 (의존성 주입 컨테이너)
  - [x] 1.8 `AppRouter.swift` 구현 (화면 라우팅 로직)
  - [x] 1.9 `SISOLearnApp.swift` 진입점 구성 (@main, 환경 객체 주입)

- [x] 2. Task 2: CoreData 스키마 및 데이터 레이어 구현
  - [x] 2.1 `SISOLearnModel.xcdatamodeld` 생성 및 Entity 정의 (ProfileEntity, LearningSessionEntity, QuizResultEntity, AchievementEntity)
  - [x] 2.2 Entity 간 관계 설정 (Profile 1:N Session, Session 1:N QuizResult, Profile 1:N Achievement)
  - [x] 2.3 `CoreDataStack.swift` 구현 (싱글톤, Lightweight Migration 설정, 백그라운드 컨텍스트)
  - [x] 2.4 도메인 엔티티 Swift 구조체 정의 (`Profile`, `LearningSession`, `QuizResult`, `Achievement`)
  - [x] 2.5 `ProfileRepositoryProtocol` 및 `ProfileRepository` 구현 (CRUD)
  - [x] 2.6 `SessionRepositoryProtocol` 및 `SessionRepository` 구현 (CRUD + 통계 쿼리)
  - [x] 2.7 CoreData 통합 테스트 작성 (`CoreDataIntegrationTests.swift`)

- [x] 3. Task 3: Keychain 보안 서비스 및 설정 화면 구현
  - [x] 3.1 `KeychainService.swift` 구현 (save, load, delete, hasAPIKey)
  - [x] 3.2 `ManageAPIKeyUseCase.swift` 구현
  - [x] 3.3 `SettingsViewModel.swift` 구현 (API Key 입력, 형식 검증, 저장/삭제)
  - [x] 3.4 `SettingsView.swift` 구현 (API Key 입력 필드, 마스킹 토글, 형식 검증, 저장/삭제 버튼)
  - [x] 3.5 Keychain 단위 테스트 작성 (`KeychainServiceTests.swift`)

- [x] 4. Task 4: 프로필 관리 모듈 구현
  - [x] 4.1 `ManageProfileUseCase.swift` 구현 (create, fetchAll, delete, updateLastActive)
  - [x] 4.2 `ProfileViewModel.swift` 구현 (프로필 목록, 생성, 삭제, 선택)
  - [x] 4.3 `ProfileSelectionView.swift` 구현 (프로필 카드 그리드, 최대 5개, 삭제)
  - [x] 4.4 `ProfileCreationView.swift` 구현 (이름 입력, 학년 선택, 아바타 선택)
  - [ ] 4.5 프로필 관련 단위 테스트 작성 (`ProfileViewModelTests.swift`, `ManageProfileUseCaseTests.swift`)
  - [ ] 4.6 프로필 수 제한 속성 기반 테스트 작성 (`ProfileLimitPropertyTests.swift`)

- [x] 5. Task 5: AI 연동 모듈 구현 (AITutorProtocol + GeminiAITutor)
  - [x] 5.1 도메인 열거형 정의 (`GradeLevel`, `Subject`, `Difficulty`)
  - [x] 5.2 `AITutorProtocol.swift` 인터페이스 정의 (generateExplanation, generateQuizzes, evaluateAnswer, generateHint, extractTopicFromVideo)
  - [x] 5.3 `GeminiRequest.swift`, `GeminiResponse.swift` 모델 정의
  - [x] 5.4 `Quiz.swift`, `AnswerFeedback.swift` 도메인 응답 모델 정의
  - [x] 5.5 `AITutorError.swift` 에러 타입 정의
  - [x] 5.6 `GeminiAITutor.swift` 구현 (URLSession, 한도 추적, 지수 백오프 재시도)
  - [x] 5.7 `RetryPolicy.swift` 구현
  - [x] 5.8 `MockAITutor.swift` 테스트용 Mock 구현
  - [x] 5.9 AI 연동 단위 테스트 작성 (`GeminiAITutorTests.swift`)
  - [x] 5.10 Quiz 수 범위 속성 기반 테스트 (`QuizCountPropertyTests.swift`)
  - [x] 5.11 힌트 단계 범위 속성 기반 테스트 (`HintLevelPropertyTests.swift`)
  - [x] 5.12 답변 길이 제한 속성 기반 테스트 (`AnswerLengthPropertyTests.swift`)

- [x] 6. Task 6: 쿠키 캐릭터 모듈 구현
  - [x] 6.1 쿠키 이미지 에셋 추가 (`Assets.xcassets/Cookie/` — 5종 감정별 이미지)
  - [x] 6.2 `CookieEmotion.swift` 구현 (감정 열거형, `from(phase:isCorrect:)` 자동 매핑)
  - [x] 6.3 `CookieMessageTemplates.swift` 구현 (인사/대기/힌트/정답/오답/완료 메시지 풀)
  - [x] 6.4 `CookiePersonaWrapper.swift` 구현 (systemPrompt, explanationPrompt, quizPrompt, feedbackPrompt, hintPrompt)
  - [x] 6.5 `CookieViewModel.swift` 구현 (speak, updateForPhase, speakAIMessage, speakError)
  - [x] 6.6 `BubbleTailShape.swift` 구현 (말풍선 꼬리 Shape)
  - [x] 6.7 `CookieBubbleView.swift` 구현 (캐릭터 이미지, 애니메이션, 말풍선, 타이핑 인디케이터)
  - [x] 6.8 `CookieCharacterView.swift` 구현 (홈 화면용 단독 캐릭터 표시)
  - [x] 6.9 쿠키 모듈 단위 테스트 작성 (`CookieViewModelTests.swift`, `CookiePersonaWrapperTests.swift`)

- [x] 7. Task 7: 대화형 학습 세션 구현
  - [x] 7.1 `LearningPhase` 열거형 정의 (greeting, explanation, quiz, answering, hintRequested, feedback, sessionComplete)
  - [x] 7.2 `StartLearningSessionUseCase.swift` 구현 (설명 + Quiz 동시 생성)
  - [x] 7.3 `SubmitAnswerUseCase.swift` 구현 (답변 평가 + QuizResult 생성)
  - [x] 7.4 `RequestHintUseCase.swift` 구현 (힌트 단계 클램핑 포함)
  - [x] 7.5 `SaveProgressUseCase.swift` 구현 (세션 저장 + 스트릭 업데이트 + 배지 확인)
  - [x] 7.6 `LearningSessionViewModel.swift` 구현 (단계 관리, 쿠키 연동, 1000자/3힌트 제한)
  - [x] 7.7 `CookieLearningView.swift` 구현 (쿠키 말풍선, Quiz 카드, 답변 입력, 진행 바)
  - [x] 7.8 `SessionCompleteView.swift` 구현 (쿠키 칭찬, 정답률, 홈 이동)
  - [x] 7.9 `HomeView.swift` 구현 (쿠키 상주, 과목 그리드, 난이도 선택)
  - [x] 7.10 학습 세션 단위 테스트 작성 (`LearningSessionViewModelTests.swift`)
  - [x] 7.11 학습 흐름 통합 테스트 작성 (`LearningFlowIntegrationTests.swift`)

- [x] 8. Task 8: YouTube 연계 학습 구현
  - [x] 8.1 `YouTubeService.swift` 구현 (extractVideoId, thumbnailURL)
  - [x] 8.2 `YouTubePlayerView.swift` 구현 (UIViewRepresentable + WKWebView, 인라인 재생)
  - [x] 8.3 `YouTubeLearningView.swift` 구현 (좌측 50% 영상 + 우측 50% 쿠키 패널)
  - [x] 8.4 YouTube URL 입력 화면 구현 (URL 입력 → 썸네일 미리보기 → 학습 시작)
  - [x] 8.5 `YouTubeService` 단위 테스트 작성 (`YouTubeServiceTests.swift`)

- [x] 9. Task 9: 학습 진행 현황 (Progress) 구현
  - [x] 9.1 `FetchAchievementsUseCase.swift` 구현 (세션 목록, 배지, 과목별 통계 조회)
  - [x] 9.2 스트릭 업데이트 로직 구현 (SaveProgressUseCase 내 — 오늘 첫 세션 완료 시 +1)
  - [x] 9.3 배지 자동 부여 로직 구현 (과목별 정답률 80% 이상 시 AchievementEntity 생성)
  - [x] 9.4 `ProgressViewModel.swift` 구현 (세션 목록, 배지, 통계, 필터)
  - [x] 9.5 `ProgressView.swift` 구현 (스트릭, 정답률, 과목별 통계, 배지 그리드, 세션 목록)
  - [x] 9.6 Progress 단위 테스트 작성 (`ProgressViewModelTests.swift`)

- [x] 10. Task 10: 에러 처리 및 오프라인 대응 구현
  - [x] 10.1 `ErrorView.swift` 구현 (에러 유형별 아이콘, 메시지, 재시도/설정 이동 버튼)
  - [x] 10.2 쿠키 에러 메시지 연동 (에러 발생 시 쿠키가 위로(🥺) 감정으로 에러 안내)
  - [x] 10.3 오프라인 감지 및 UI 처리 (NetworkMonitor → 쿠키 오프라인 메시지 + 배너)
  - [x] 10.4 API 분당 한도 초과 처리 (60초 대기 타이머 + 쿠키 안내 메시지)
  - [x] 10.5 일일 한도 초과 처리 (학습 중단 + 쿠키 내일 만나요 메시지)
  - [x] 10.6 CoreData 저장 실패 처리 (재시도 버튼 + 쿠키 안내)
  - [x] 10.7 에러 처리 단위 테스트 작성 (`ErrorHandlingTests.swift`)

- [x] 11. Task 11: UI 완성도 및 접근성 개선
  - [x] 11.1 앱 전체 색상 테마 정의 (`AppTheme.swift` — 쿠키 오렌지 계열)
  - [x] 11.2 다크 모드 지원 (모든 View에 시스템 적응형 색상 적용)
  - [x] 11.3 접근성 적용 (터치 영역 44pt, VoiceOver 레이블, Dynamic Type)
  - [x] 11.4 iPad 가로/세로 모드 레이아웃 대응 (horizontalSizeClass 활용)
  - [x] 11.5 로딩 인디케이터 통일 (`LoadingOverlayView.swift` — 쿠키 로딩 애니메이션)
  - [x] 11.6 스켈레톤 UI 구현 (`SkeletonView.swift` — 설명/Quiz 로딩 중)
  - [ ] 11.7 앱 아이콘 및 런치 스크린 설정

- [ ] 12. Task 12: 테스트 완성 및 TestFlight 배포 준비
  - [ ] 12.1 전체 단위 테스트 커버리지 확인 (Domain 90%, ViewModel 80% 목표)
  - [ ] 12.2 속성 기반 테스트(PBT) 전체 실행 확인 (CP-1~CP-7)
  - [ ] 12.3 전체 학습 흐름 통합 테스트 실행 (`LearningFlowIntegrationTests`)
  - [ ] 12.4 iPad Air M1 / M5 시뮬레이터 테스트
  - [ ] 12.5 App Store Connect 앱 등록 및 TestFlight 설정
  - [ ] 12.6 내부 테스터(두 딸) 초대 및 TestFlight 배포
  - [ ] 12.7 피드백 수집 및 버그 수정

## Task Dependency Graph

```
1 (프로젝트 설정)
  └→ 2 (CoreData) → 4 (프로필) → 7 (학습 세션) → 8 (YouTube)
                                                  → 9 (Progress)
  └→ 3 (Keychain) → 5 (AI 연동) → 6 (쿠키 캐릭터) → 7 (학습 세션)
7 + 8 + 9 + 10 → 11 (UI 완성도) → 12 (테스트 + 배포)
```

## Notes

- task-guides/ 폴더의 각 task 가이드 파일을 참고하여 구현한다
- 각 task 완료 시 이 파일의 체크박스를 업데이트한다
- 1.1은 Xcode GUI 작업이므로 수동으로 진행 후 체크한다
