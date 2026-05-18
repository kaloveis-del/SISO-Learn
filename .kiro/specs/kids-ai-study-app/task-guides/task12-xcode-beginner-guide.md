# Task 12 초보자 가이드: Xcode 빌드부터 TestFlight 배포까지

> 이 가이드는 Xcode를 처음 사용하는 분을 위해 스크린샷 없이도 따라할 수 있도록 작성했습니다.

---

## 사전 준비물

| 항목 | 필요 여부 | 비용 |
|------|-----------|------|
| Mac (Xcode 설치됨) | 필수 | 무료 |
| Apple ID | 필수 | 무료 |
| Apple Developer Program | TestFlight 배포 시 필수 | 연 $99 (약 13만원) |
| iPad (테스트용) | 시뮬레이터로 대체 가능 | - |

> ⚠️ **중요**: TestFlight 배포(12.5~12.7)는 Apple Developer Program 유료 가입이 필요합니다.
> 시뮬레이터 테스트(12.4)는 무료로 가능합니다.

---

## 12.4 iPad 시뮬레이터 테스트 (무료, 지금 바로 가능)

### Step 1: Xcode에서 프로젝트 열기

1. Xcode 실행
2. 상단 메뉴 → **File → Open...**
3. `/Volumes/SanDisk/kiro_project/SISOLearn/` 폴더로 이동
4. `SISOLearn.xcodeproj` 파일 선택 → **Open** 클릭

### Step 2: 소스 파일을 프로젝트에 추가하기

현재 Swift 파일들이 폴더에는 있지만 Xcode 프로젝트에 등록되지 않았을 수 있습니다.

1. Xcode 좌측 **Navigator** (파일 목록 패널)에서 `SISOLearn` 폴더 우클릭
2. **Add Files to "SISOLearn"...** 선택
3. `SISOLearn/Core/` 폴더 선택 → 하단 옵션:
   - ✅ **Copy items if needed** 체크 해제 (이미 같은 위치에 있으므로)
   - ✅ **Create groups** 선택
   - Target: **SISOLearn** 체크
4. **Add** 클릭
5. 같은 방법으로 `SISOLearn/Modules/` 폴더도 추가

> 💡 **팁**: 한 번에 여러 폴더를 선택할 수 있습니다 (Cmd 키 누르고 클릭)

### Step 3: 시뮬레이터 선택

1. Xcode 상단 중앙에 기기 선택 드롭다운이 있습니다
   - 현재 "My Mac" 또는 다른 기기로 되어 있을 수 있음
2. 클릭 → **iPad Air (5th generation)** 선택
   - 목록에 없으면: **Window → Devices and Simulators → Simulators 탭 → + 버튼**으로 추가

### Step 4: 빌드 및 실행

1. 키보드 단축키: **Cmd + R** (또는 좌상단 ▶️ 재생 버튼 클릭)
2. 처음 빌드 시 1~2분 소요
3. 성공하면 iPad 시뮬레이터가 열리고 앱이 실행됨

### Step 5: 빌드 에러가 나면?

흔한 에러와 해결법:

| 에러 메시지 | 원인 | 해결 |
|------------|------|------|
| "No such module 'SwiftUI'" | 타겟이 macOS로 설정됨 | 기기를 iPad 시뮬레이터로 변경 |
| "Use of unresolved identifier" | 파일이 프로젝트에 추가 안 됨 | Step 2 다시 진행 |
| "Multiple commands produce" | 파일 중복 | 중복 파일 제거 (우클릭 → Delete → Move to Trash) |
| "@main attribute" 에러 | SISOLearnApp.swift가 2개 | 기본 생성된 것 삭제, 우리가 만든 것만 유지 |

### Step 6: 테스트 실행

1. 키보드 단축키: **Cmd + U** (전체 테스트 실행)
2. 좌측 Navigator에서 테스트 아이콘(다이아몬드) 클릭하면 테스트 목록 표시
3. 각 테스트 옆 ▶️ 버튼으로 개별 실행 가능
4. ✅ 초록 = 통과, ❌ 빨강 = 실패

---

## 12.5 App Store Connect 등록 (유료 — Apple Developer Program 필요)

### Step 1: Apple Developer Program 가입

1. 브라우저에서 https://developer.apple.com/programs/ 접속
2. **Enroll** 클릭
3. Apple ID로 로그인
4. 개인 개발자로 등록 (Individual)
5. 연 $99 결제 (카드 또는 Apple Pay)
6. 승인까지 24~48시간 소요

> 💡 **팁**: 가입 전에 12.4 시뮬레이터 테스트를 먼저 완료하세요. 앱이 정상 동작하는지 확인 후 결제해도 늦지 않습니다.

### Step 2: App Store Connect에서 앱 등록

1. https://appstoreconnect.apple.com 접속 → Apple ID 로그인
2. **My Apps** → 좌상단 **+** 버튼 → **New App**
3. 입력값:

| 항목 | 값 |
|------|-----|
| Platforms | iOS |
| Name | SISO-Learn |
| Primary Language | Korean |
| Bundle ID | com.sisolearn.SISOLearn (Xcode에서 설정한 것과 동일) |
| SKU | sisolearn-001 |
| User Access | Full Access |

4. **Create** 클릭

### Step 3: Xcode에서 Signing 설정

1. Xcode에서 프로젝트 열기
2. 좌측 Navigator에서 **SISOLearn** (파란 아이콘, 최상위) 클릭
3. 중앙 패널에서 **Signing & Capabilities** 탭 선택
4. **Team** 드롭다운에서 본인 Developer 계정 선택
5. **Bundle Identifier**: `com.sisolearn.SISOLearn` 확인
6. ✅ **Automatically manage signing** 체크

> 에러 없이 "Signing Certificate" 와 "Provisioning Profile"이 표시되면 성공

---

## 12.6 TestFlight 배포

### Step 1: Archive 생성

1. Xcode 상단 기기 선택 → **Any iOS Device (arm64)** 선택 (시뮬레이터 아님!)
2. 상단 메뉴 → **Product → Archive**
3. 빌드 완료까지 2~5분 대기
4. 성공하면 **Organizer** 창이 자동으로 열림

### Step 2: App Store Connect에 업로드

1. Organizer에서 방금 만든 Archive 선택
2. 우측 **Distribute App** 버튼 클릭
3. **TestFlight & App Store** 선택 → **Next**
4. **Upload** 선택 → **Next**
5. 모든 옵션 기본값 유지 → **Next**
6. **Upload** 클릭
7. 업로드 완료까지 5~10분 대기

### Step 3: TestFlight에서 테스터 초대

1. https://appstoreconnect.apple.com → **My Apps** → **SISO-Learn**
2. **TestFlight** 탭 클릭
3. 좌측 **Internal Testing** → **+** 버튼 → **New Group**
4. 그룹 이름: "가족 테스터"
5. **Add Testers** → 두 딸의 Apple ID 이메일 입력
6. **Add** 클릭

### Step 4: 두 딸의 iPad에서 설치

1. 두 딸의 iPad에서 **App Store** → **TestFlight** 앱 검색 → 설치
2. 이메일로 온 TestFlight 초대 링크 탭
3. TestFlight 앱에서 **SISO-Learn** → **설치** 탭
4. 홈 화면에 앱 아이콘 생성 → 실행!

---

## 12.7 피드백 수집

### TestFlight 내장 피드백

- 앱 사용 중 iPad를 흔들면 → 스크린샷 + 피드백 전송 화면이 뜸
- App Store Connect → TestFlight → Feedback 탭에서 확인 가능

### 직접 물어보기 (가장 중요!)

아이들에게 물어볼 질문:

```
1. 쿠키가 말하는 게 재미있어?
2. 문제가 너무 어렵거나 쉽지 않아?
3. 힌트가 도움이 됐어?
4. 어떤 과목이 제일 재미있었어?
5. 앱에서 불편한 게 있었어?
6. 쿠키한테 바꿨으면 하는 거 있어?
```

### 버그 수정 후 재배포

1. Xcode에서 코드 수정
2. `Info.plist` 또는 프로젝트 설정에서 버전 올리기 (1.0.0 → 1.0.1)
3. 다시 **Product → Archive → Distribute App → Upload**
4. TestFlight에 자동으로 새 버전 배포됨 (테스터에게 알림)

---

## 자주 묻는 질문 (FAQ)

**Q: Apple Developer Program 없이 iPad에서 테스트할 수 있나요?**
A: 네! 무료 Apple ID로도 본인 iPad에 직접 설치 가능합니다.
- Xcode에서 기기 선택 시 USB로 연결된 실제 iPad 선택
- Team에 무료 Apple ID 선택
- 7일마다 재설치 필요 (무료 계정 제한)

**Q: 시뮬레이터에서 Gemini API 테스트가 되나요?**
A: 네! 시뮬레이터도 인터넷 연결이 되므로 API 호출 가능합니다.

**Q: 빌드가 안 되면 어떻게 하나요?**
A: 상단 메뉴 → **Product → Clean Build Folder** (Cmd+Shift+K) 후 다시 빌드해보세요.

**Q: SwiftData 관련 에러가 나면?**
A: Xcode가 자동 생성한 `Item.swift` 파일이 남아있을 수 있습니다. 삭제하세요.

---

## 요약 순서

```
1. Xcode에서 프로젝트 열기
2. 소스 파일 추가 (Add Files)
3. iPad 시뮬레이터 선택
4. Cmd+B (빌드) → 에러 수정
5. Cmd+R (실행) → 시뮬레이터에서 확인
6. Cmd+U (테스트) → 모두 통과 확인
7. (선택) Apple Developer 가입 → Archive → TestFlight 배포
```
