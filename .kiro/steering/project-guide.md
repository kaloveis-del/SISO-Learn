# SISO-Learn 프로젝트 시작 가이드

> 이 파일은 새 프로젝트(SISO-Learn) 시작 시 참고용 가이드입니다.
> SISO-Learn 폴더를 Kiro에서 열면 이 파일을 `.kiro/steering/project-guide.md` 로 이동하여 사용하세요.

---

## 프로젝트 개요

- **프로젝트명**: SISO-Learn
- **GitHub**: https://github.com/kaloveis-del/SISO-Learn.git
- **목적**: 집에서 iPad로 공부하는 두 딸을 위한 AI 기반 인터랙티브 학습 앱

---

## 사용자 정보

| 구분 | 학년 | 기기 |
|------|------|------|
| 큰딸 | 중학교 2학년 | iPad Air M5 (최신) |
| 둘째딸 | 초등학교 5학년 | iPad Air M1 |

---

## 핵심 요구사항 (사용자 원문)

1. 큰딸은 중학교 2학년이고 둘째 딸은 초등학교 5학년이다
2. 두 딸 모두 아이패드 에어를 가지고 있어. 큰딸은 아이패드에어 M5 최신, 둘째딸은 아이패드에어 M1
3. 둘 다 유튜브 및 크래프트 게임을 좋아해. 영상을 보면서 쉽게 AI랑 공부하는 걸 만들고 싶어
4. 연동할 AI는 현재 Gemini Pro를 쓰고 있는데, 무료로 연동 가능한 AI면 좋고, 없으면 유료라도 정확하게 애들이 공부 잘 할 수 있는 것으로 연동
5. 보기만 하는 건 둘 다 싫어해서 주고받는 걸 좋아하니, 설명을 보고 입력하거나 대답하는 방식으로 공부할 수 있게 만들려고 해
6. 처음 시작하는 앱 개발이므로 스택별로 차근차근 나눠서 쉽게 진행할 수 있도록 해줘

---

## AI 연동 결정

- **1순위 (무료)**: Google Gemini API (Gemini 2.0 Flash)
  - 현재 사용자가 Gemini Pro 사용 중 → API 키 재활용 가능
  - Google AI Studio에서 무료 API 키 발급: https://aistudio.google.com
  - 무료 한도: 분당 15회 요청, 일 1,500회 요청 (2025년 기준)
- **2순위 (유료 대안)**: OpenAI GPT-4o Mini (저렴하고 교육용으로 정확)
- **추상화 레이어 필수**: AI 제공자를 나중에 교체할 수 있도록 `AITutorProtocol` 인터페이스로 설계

---

## 기술 스택

| 항목 | 선택 |
|------|------|
| 플랫폼 | iPadOS 16.0 이상 |
| 언어 | Swift 5.9+ |
| UI 프레임워크 | SwiftUI |
| AI 연동 | Google Gemini API (gemini-2.0-flash) |
| 로컬 저장소 | CoreData (Progress) + UserDefaults (Profile) |
| 보안 저장소 | iOS Keychain (API Key) |
| 영상 재생 | WKWebView (YouTube embed) |
| 아키텍처 | MVVM + Clean Architecture (모듈 분리) |
| 테스트 | XCTest + Swift Testing |
| 배포 | TestFlight (단계별 내부 테스트) |

---

## 단계별 개발 계획

### 1단계 — MVP (가장 먼저 완성)
- [ ] Xcode 프로젝트 생성 (SwiftUI, iPadOS 타겟)
- [ ] GitHub 연동 설정
- [ ] 프로필 관리 화면 (최대 5개, 학년 선택)
- [ ] Gemini API 연동 모듈 (`AITutorProtocol` 추상화)
- [ ] 기본 질문-답변 학습 화면 (Quiz → Answer → Feedback 사이클)
- [ ] API Key 설정 화면 (Keychain 저장)

### 2단계 — 콘텐츠 강화
- [ ] 유튜브 영상 연계 학습 (WKWebView + AI 채팅 동시 표시)
- [ ] 학년별 맞춤 콘텐츠 (초5/중2 어휘 수준 분리)
- [ ] 과목 선택 (수학, 영어, 과학, 국어)
- [ ] 난이도 선택 (쉬움/보통/어려움)

### 3단계 — 동기부여 & 완성도
- [ ] 학습 진행 현황 화면 (Progress)
- [ ] 연속 학습 스트릭 (Streak)
- [ ] 성취 배지 시스템 (과목별 정답률 80% 달성 시)
- [ ] 다크 모드 지원
- [ ] 접근성 (WCAG 2.1 AA, 최소 터치 영역 44×44pt)

---

## 학습 흐름 (UX Flow)

```
앱 실행
  └→ 프로필 선택 화면
       └→ 프로필 선택 or 새 프로필 생성 (이름 + 학년)
            └→ 홈 화면
                 └→ 과목 선택 → 난이도 선택 → 학습 시작
                      └→ [영상 시청 (선택)] → AI 설명 (500자 이하)
                           └→ Quiz 출제
                                └→ 학습자 답변 입력 (최대 1,000자)
                                     ├→ 힌트 요청 (최대 3단계)
                                     └→ 제출 → AI Feedback (정답/오답 + 설명)
                                          └→ 다음 Quiz (3~10개 반복)
                                               └→ 세션 완료 → 정답률 표시 → Progress 저장
```

---

## 주요 설계 원칙

1. **쌍방향 학습**: 보기만 하는 방식 금지. 반드시 입력/대답 유도
2. **학년 맞춤**: 초5는 한자어 최소화·짧은 문장, 중2는 교과서 용어 포함
3. **힌트 시스템**: 정답 직접 제공 금지, 최대 3단계 단계적 힌트
4. **모듈 분리**: 각 기능을 독립 모듈로 설계해 단계별 추가 가능
5. **AI 교체 가능**: `AITutorProtocol`로 추상화하여 Gemini → 다른 AI로 교체 용이

---

## 요구사항 문서 위치

새 프로젝트에서 Kiro Spec을 시작하면 아래 경로에 자동 생성됩니다:

```
SISO-Learn/
  .kiro/
    specs/
      kids-ai-study-app/
        requirements.md   ← 상세 요구사항 (8개 영역)
        design.md         ← 기술 설계 (생성 예정)
        tasks.md          ← 구현 태스크 목록 (생성 예정)
```

---

## Kiro에서 새 프로젝트 시작하는 방법

1. 터미널에서 클론:
   ```bash
   cd /Volumes/SanDisk/kiro_project
   git clone https://github.com/kaloveis-del/SISO-Learn.git
   ```

2. Kiro에서 폴더 열기:
   - `File → Open Folder` (또는 `Cmd+O`)
   - `/Volumes/SanDisk/kiro_project/SISO-Learn` 선택

3. 이 가이드 파일을 Kiro steering 폴더로 이동:
   ```bash
   mkdir -p .kiro/steering
   mv SISO-Learn-project-guide.md .kiro/steering/project-guide.md
   ```

4. Kiro 채팅에서 이어서 진행:
   > "SISO-Learn 앱 개발을 이어서 진행해줘. 요구사항은 이미 정리되어 있고 기술 설계 문서(design.md)부터 만들어줘"

---

## 참고 링크

- Google AI Studio (Gemini API 키 발급): https://aistudio.google.com
- Gemini API 문서: https://ai.google.dev/docs
- Apple SwiftUI 문서: https://developer.apple.com/documentation/swiftui
- YouTubePlayerKit (Swift Package): https://github.com/SvenTiigi/YouTubePlayerKit
