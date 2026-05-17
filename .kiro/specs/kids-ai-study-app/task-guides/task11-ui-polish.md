# Task 11 가이드: UI 완성도 및 접근성 개선

> **단계**: 6단계 (완성) | **선행 태스크**: Task 7, 8, 9, 10 | **후행 태스크**: Task 12

---

## 목표

앱 전체의 시각적 완성도를 높이고, 다크 모드·가로/세로 모드·접근성(VoiceOver)을 지원한다.
쿠키 오렌지 테마를 일관되게 적용하고, 로딩 상태와 스켈레톤 UI를 통일한다.

---

## 체크리스트

- [x] 11.1 앱 전체 색상 테마 정의
- [x] 11.2 다크 모드 지원
- [x] 11.3 접근성 적용 (터치 영역, VoiceOver, Dynamic Type)
- [x] 11.4 iPad 가로/세로 모드 레이아웃 대응
- [x] 11.5 로딩 인디케이터 통일
- [x] 11.6 스켈레톤 UI 구현
- [ ] 11.7 앱 아이콘 및 런치 스크린 설정 (이미지 에셋 준비 후 진행)

---

## 상세 구현 가이드

### 11.1 앱 전체 색상 테마 정의

경로: `Core/Constants/AppTheme.swift`

```swift
import SwiftUI

enum AppTheme {
    // MARK: - 주요 색상
    static let primary      = Color("CookieOrange")   // #FF8C00
    static let secondary    = Color("CookieBrown")    // #8B4513
    static let background   = Color("AppBackground")  // 라이트: #FFF8F0 / 다크: #1C1C1E
    static let cardBg       = Color("CardBackground") // 라이트: white / 다크: #2C2C2E
    static let accent       = Color("AccentYellow")   // #FFD700

    // MARK: - 과목별 색상
    static let mathColor    = Color("MathBlue")       // #4A90D9
    static let englishColor = Color("EnglishGreen")   // #5CB85C
    static let scienceColor = Color("SciencePurple")  // #9B59B6
    static let koreanColor  = Color("KoreanRed")      // #E74C3C

    static func subjectColor(_ subject: Subject) -> Color {
        switch subject {
        case .math:    return mathColor
        case .english: return englishColor
        case .science: return scienceColor
        case .korean:  return koreanColor
        }
    }

    // MARK: - 타이포그래피
    static let titleFont    = Font.system(.largeTitle, design: .rounded, weight: .bold)
    static let headlineFont = Font.system(.headline,   design: .rounded, weight: .semibold)
    static let bodyFont     = Font.system(.body,       design: .rounded)
    static let captionFont  = Font.system(.caption,    design: .rounded)
}
```

`Assets.xcassets`에 Color Set 추가:

| 이름 | Light | Dark |
|------|-------|------|
| CookieOrange | #FF8C00 | #FF9F1C |
| CookieBrown | #8B4513 | #A0522D |
| AppBackground | #FFF8F0 | #1C1C1E |
| CardBackground | #FFFFFF | #2C2C2E |
| AccentYellow | #FFD700 | #FFD700 |

---

### 11.2 다크 모드 지원

모든 View에서 하드코딩된 색상 대신 `AppTheme` 또는 시스템 색상을 사용한다.

```swift
// ❌ 하드코딩 (다크 모드 미지원)
.background(Color.white)
.foregroundColor(Color.black)

// ✅ 시스템 적응형
.background(Color(.systemBackground))
.foregroundColor(Color(.label))

// ✅ AppTheme 사용
.background(AppTheme.cardBg)
.foregroundColor(AppTheme.primary)
```

`SISOLearnApp.swift`에 다크 모드 테스트용 Preview 추가:

```swift
#Preview("다크 모드") {
    ContentView()
        .preferredColorScheme(.dark)
}
```

---

### 11.3 접근성 적용

#### 최소 터치 영역 44×44pt

```swift
// 모든 버튼에 적용
Button("제출") { viewModel.submitAnswer() }
    .frame(minWidth: 44, minHeight: 44)  // 최소 터치 영역

// 또는 contentShape 사용
.contentShape(Rectangle())
.frame(minHeight: 44)
```

#### VoiceOver 레이블

```swift
// 쿠키 캐릭터 (장식용 — 숨김)
CookieCharacterView(emotion: .excited)
    .accessibilityHidden(true)

// 프로필 카드
ProfileCardView(profile: profile)
    .accessibilityLabel("\(profile.name), \(profile.gradeLevel.rawValue)")
    .accessibilityHint("탭하면 이 프로필로 학습을 시작해요")

// 힌트 버튼
Button("💡 힌트") { viewModel.requestHint() }
    .accessibilityLabel("힌트 요청")
    .accessibilityValue("\(3 - viewModel.hintCount)회 남음")
    .disabled(!viewModel.canRequestHint)

// 진행 바
ProgressView(value: viewModel.progress)
    .accessibilityLabel("학습 진행률")
    .accessibilityValue("\(viewModel.currentQuizIndex + 1)번째 문제 / 전체 \(viewModel.quizzes.count)문제")

// 쿠키 말풍선
CookieBubbleView(cookieVM: cookieVM)
    .accessibilityLabel("쿠키: \(cookieVM.currentMessage)")
```

#### Dynamic Type 지원

```swift
// 고정 폰트 크기 대신 상대적 크기 사용
Text("제목")
    .font(.title2)           // ✅ Dynamic Type 지원
    // .font(.system(size: 22)) // ❌ 고정 크기

// 최소/최대 크기 제한이 필요한 경우
Text(cookieVM.currentMessage)
    .font(.body)
    .minimumScaleFactor(0.8)
    .lineLimit(5)
```

---

### 11.4 iPad 가로/세로 모드 레이아웃 대응

`GeometryReader`와 `horizontalSizeClass`를 활용한다.

```swift
struct AdaptiveLearningLayout: View {
    @Environment(\.horizontalSizeClass) private var hSizeClass
    @StateObject var viewModel: LearningSessionViewModel

    var body: some View {
        if hSizeClass == .regular {
            // iPad 가로 모드: 2컬럼 레이아웃
            HStack(spacing: 0) {
                // 좌측: 쿠키 + 설명
                cookiePanel
                    .frame(maxWidth: .infinity)
                Divider()
                // 우측: Quiz + 답변
                quizPanel
                    .frame(maxWidth: .infinity)
            }
        } else {
            // iPad 세로 모드 / 작은 화면: 단일 컬럼
            ScrollView {
                VStack(spacing: 16) {
                    cookiePanel
                    quizPanel
                }
                .padding()
            }
        }
    }
}
```

`HomeView` 과목 그리드도 화면 크기에 따라 컬럼 수 조정:

```swift
let columns = Array(repeating: GridItem(.flexible(), spacing: 16),
                    count: hSizeClass == .regular ? 4 : 2)
LazyVGrid(columns: columns, spacing: 16) {
    ForEach(Subject.allCases, id: \.self) { subject in
        SubjectCardView(subject: subject)
    }
}
```

---

### 11.5 로딩 인디케이터 통일

경로: `Core/Views/LoadingOverlayView.swift`

```swift
import SwiftUI

/// 앱 전체에서 통일된 로딩 오버레이
struct LoadingOverlayView: View {
    let message: String

    var body: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                // 쿠키 로딩 애니메이션
                Text("🐶")
                    .font(.system(size: 48))
                    .rotationEffect(.degrees(loadingAngle))
                    .animation(.linear(duration: 1.0).repeatForever(autoreverses: false),
                               value: loadingAngle)

                ProgressView()
                    .scaleEffect(1.2)
                    .tint(AppTheme.primary)

                Text(message)
                    .font(AppTheme.bodyFont)
                    .foregroundColor(.white)
            }
            .padding(32)
            .background(Color(.systemBackground).opacity(0.95))
            .cornerRadius(20)
            .shadow(radius: 10)
        }
    }

    @State private var loadingAngle: Double = 0

    // onAppear에서 loadingAngle = 360 설정
}

// 사용 예시
.overlay {
    if viewModel.isLoading {
        LoadingOverlayView(message: "쿠키가 생각하는 중... 🤔")
    }
}
```

AI 요청별 로딩 메시지:

| 상황 | 메시지 |
|------|--------|
| 설명 생성 | "쿠키가 설명을 준비하는 중... 🐾" |
| Quiz 생성 | "쿠키가 문제를 만드는 중... 🤔" |
| 답변 평가 | "쿠키가 답변을 확인하는 중... 😊" |
| 힌트 생성 | "쿠키가 힌트를 생각하는 중... 🤔" |

---

### 11.6 스켈레톤 UI 구현

경로: `Core/Views/SkeletonView.swift`

```swift
import SwiftUI

/// 로딩 중 콘텐츠 자리를 채우는 스켈레톤 뷰
struct SkeletonView: View {
    @State private var isAnimating = false

    var body: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(
                LinearGradient(
                    colors: [Color(.systemGray5), Color(.systemGray4), Color(.systemGray5)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .opacity(isAnimating ? 0.6 : 1.0)
            .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true),
                       value: isAnimating)
            .onAppear { isAnimating = true }
    }
}

/// 쿠키 설명 카드 스켈레톤
struct ExplanationSkeletonView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SkeletonView().frame(height: 20)
            SkeletonView().frame(height: 20).padding(.trailing, 40)
            SkeletonView().frame(height: 20).padding(.trailing, 80)
            SkeletonView().frame(height: 20).padding(.trailing, 20)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.06), radius: 4)
    }
}

// 사용 예시 (CookieLearningView)
if viewModel.isLoading && viewModel.explanation.isEmpty {
    ExplanationSkeletonView()
} else {
    explanationCard
}
```

---

### 11.7 앱 아이콘 및 런치 스크린 설정

#### 앱 아이콘

1. `Assets.xcassets` → `AppIcon` 선택
2. 1024×1024 PNG 이미지 추가 (쿠키 강아지 캐릭터 + "SISO-Learn" 텍스트)
3. Xcode가 자동으로 모든 크기 생성

임시 아이콘 (이미지 없을 때):
- 배경: 오렌지(#FF8C00)
- 중앙: 🐶 이모지 (흰색 원 안에)

#### 런치 스크린

`LaunchScreen.storyboard` 또는 SwiftUI `LaunchScreen` 설정:

```swift
// Info.plist에 추가
// UILaunchScreen → UIImageName: "LaunchLogo"
// 또는 SwiftUI 방식:
```

`Assets.xcassets`에 `LaunchLogo` 이미지 추가:
- 배경: 오렌지 그라디언트
- 중앙: 쿠키 캐릭터 + "SISO-Learn" 텍스트

---

## 완료 기준 확인

| 항목 | 확인 방법 |
|------|-----------|
| 다크 모드 | 설정 → 다크 모드 전환 후 모든 화면 확인 |
| 터치 영역 | Accessibility Inspector에서 모든 버튼 44pt 이상 확인 |
| VoiceOver | 설정 → 손쉬운 사용 → VoiceOver 켜고 화면 탐색 |
| 가로/세로 | iPad 회전 시 레이아웃 깨짐 없음 확인 |
| 로딩 | AI 요청 중 쿠키 로딩 오버레이 표시 확인 |
| 스켈레톤 | 설명 로딩 중 스켈레톤 카드 표시 확인 |

---

## 다음 단계

Task 11 완료 후 **Task 12 (테스트 완성 및 TestFlight 배포)** 로 진행한다.
