# Task 1 가이드: Xcode 프로젝트 초기 설정 및 아키텍처 기반 구성

> **단계**: 1단계 (기반) | **선행 태스크**: 없음 | **후행 태스크**: Task 2, Task 3

---

## 목표

SISO-Learn 앱의 뼈대를 만든다. 이 태스크가 완료되면 iPad 시뮬레이터에서 앱이 빌드·실행되고, 이후 모든 모듈이 올라갈 폴더 구조와 공통 인프라가 준비된다.

---

## 체크리스트

- [x] 1.1 Xcode 프로젝트 생성
- [x] 1.2 GitHub 연결 및 초기 커밋
- [x] 1.3 폴더 구조 생성
- [x] 1.4 `AppConstants.swift` 작성
- [x] 1.5 Extensions 파일 작성
- [x] 1.6 `NetworkMonitor.swift` 구현
- [x] 1.7 `AppDependencyContainer.swift` 구현
- [x] 1.8 `AppRouter.swift` 구현
- [x] 1.9 `SISOLearnApp.swift` 진입점 구성

---

## 상세 구현 가이드

### 1.1 Xcode 프로젝트 생성

1. Xcode 실행 → **Create New Project**
2. **iOS → App** 선택
3. 설정값:
   - Product Name: `SISOLearn`
   - Bundle Identifier: `com.sisolearn.app`
   - Interface: **SwiftUI**
   - Language: **Swift**
   - Minimum Deployments: **iPadOS 16.0**
4. 저장 위치: `/Volumes/SanDisk/kiro_project/SISO-Learn/`

> ⚠️ **주의**: "Include Tests" 체크박스를 반드시 선택한다.

---

### 1.2 GitHub 연결 및 초기 커밋

터미널에서 실행:

```bash
cd /Volumes/SanDisk/kiro_project/SISO-Learn
git init
git remote add origin https://github.com/kaloveis-del/SISO-Learn.git
git add .
git commit -m "feat: initial Xcode project setup"
git push -u origin main
```

`.gitignore`에 반드시 포함:
```
*.xcuserstate
DerivedData/
.DS_Store
*.xcworkspace/xcuserdata/
```

---

### 1.3 폴더 구조 생성

Xcode에서 아래 그룹(폴더)을 생성한다 (File → New → Group):

```
SISOLearn/
├── App/
├── Modules/
│   ├── Cookie/
│   │   ├── Domain/
│   │   ├── Data/
│   │   └── Presentation/
│   ├── Profile/
│   │   ├── Domain/
│   │   ├── Data/
│   │   └── Presentation/
│   ├── Learning/
│   │   ├── Domain/
│   │   ├── Data/
│   │   └── Presentation/
│   ├── AITutor/
│   │   ├── Domain/
│   │   └── Data/
│   ├── YouTube/
│   ├── Progress/
│   │   ├── Domain/
│   │   └── Presentation/
│   └── Settings/
│       ├── Domain/
│       ├── Data/
│       └── Presentation/
├── Core/
│   ├── CoreData/
│   ├── Network/
│   ├── Extensions/
│   └── Constants/
└── Tests/
    ├── UnitTests/
    ├── IntegrationTests/
    └── PropertyTests/
```

---

### 1.4 `AppConstants.swift` 작성

경로: `Core/Constants/AppConstants.swift`

```swift
import Foundation

// MARK: - Gemini API 한도 상수
enum GeminiAPILimits {
    static let requestsPerMinute = 15
    static let requestsPerDay = 1500
    static let maxOutputTokens = 1024
    static let explanationMaxChars = 500
    static let answerMaxChars = 1000
    static let minQuizCount = 3
    static let maxQuizCount = 10
    static let maxHintLevel = 3
}

// MARK: - 앱 전역 상수
enum AppConstants {
    static let maxProfileCount = 5
    static let achievementAccuracyThreshold = 0.8  // 80%
    static let bundleIdentifier = "com.sisolearn.app"
}

// MARK: - Keychain 키
enum KeychainKeys {
    static let service = "com.sisolearn.app"
    static let geminiAPIKey = "gemini_api_key"
}
```

---

### 1.5 Extensions 파일 작성

**`Core/Extensions/String+Extensions.swift`**

```swift
import Foundation

extension String {
    /// 앞뒤 공백 제거 후 비어있는지 확인
    var isBlank: Bool {
        trimmingCharacters(in: .whitespaces).isEmpty
    }

    /// 최대 길이로 자르기
    func truncated(to maxLength: Int) -> String {
        guard count > maxLength else { return self }
        return String(prefix(maxLength))
    }
}
```

**`Core/Extensions/Date+Extensions.swift`**

```swift
import Foundation

extension Date {
    /// 오늘 날짜인지 확인
    var isToday: Bool {
        Calendar.current.isDateInToday(self)
    }

    /// 어제 날짜인지 확인
    var isYesterday: Bool {
        Calendar.current.isDateInYesterday(self)
    }

    /// "yyyy.MM.dd" 형식 문자열
    var displayString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy.MM.dd"
        return formatter.string(from: self)
    }
}
```

**`Core/Extensions/Collection+Extensions.swift`**

```swift
extension Collection {
    /// 인덱스 범위를 벗어나면 nil 반환하는 안전한 서브스크립트
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
```

---

### 1.6 `NetworkMonitor.swift` 구현

경로: `Core/Network/NetworkMonitor.swift`

```swift
import Network
import Combine
import Foundation

final class NetworkMonitor: ObservableObject {

    static let shared = NetworkMonitor()

    @Published var isConnected: Bool = true
    @Published var connectionType: ConnectionType = .unknown

    enum ConnectionType {
        case wifi, cellular, unknown
    }

    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "com.sisolearn.networkmonitor")

    private init() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.isConnected = path.status == .satisfied
                if path.usesInterfaceType(.wifi) {
                    self?.connectionType = .wifi
                } else if path.usesInterfaceType(.cellular) {
                    self?.connectionType = .cellular
                } else {
                    self?.connectionType = .unknown
                }
            }
        }
        monitor.start(queue: queue)
    }

    deinit {
        monitor.cancel()
    }
}
```

---

### 1.7 `AppDependencyContainer.swift` 구현

경로: `App/AppDependencyContainer.swift`

```swift
import Foundation

/// 앱 전체 의존성을 관리하는 컨테이너
/// 각 모듈의 UseCase, Repository, Service 인스턴스를 생성하고 주입한다
@MainActor
final class AppDependencyContainer: ObservableObject {

    // MARK: - Core Services (Task 2, 3에서 채워짐)
    // lazy var coreDataStack = CoreDataStack.shared
    // lazy var keychainService = KeychainService()

    // MARK: - 싱글톤
    static let shared = AppDependencyContainer()
    private init() {}
}
```

> 📝 **참고**: 이 파일은 Task 2~5를 진행하면서 점진적으로 채워진다. 지금은 빈 컨테이너로 시작한다.

---

### 1.8 `AppRouter.swift` 구현

경로: `App/AppRouter.swift`

```swift
import SwiftUI

/// 앱 전체 화면 라우팅을 담당
/// NavigationPath 기반으로 화면 전환을 관리한다
@MainActor
final class AppRouter: ObservableObject {

    @Published var path = NavigationPath()
    @Published var selectedProfile: String? = nil  // Task 4에서 Profile 타입으로 교체
    @Published var hasAPIKey: Bool = false          // Task 3에서 Keychain 연동

    enum Route: Hashable {
        case profileSelection
        case profileCreation
        case home
        case settings
        case progress
        case learningSession
        case youtubeLearning
    }

    func navigate(to route: Route) {
        path.append(route)
    }

    func goBack() {
        path.removeLast()
    }

    func goToRoot() {
        path.removeLast(path.count)
    }
}
```

---

### 1.9 `SISOLearnApp.swift` 진입점 구성

경로: `App/SISOLearnApp.swift`

```swift
import SwiftUI

@main
struct SISOLearnApp: App {

    @StateObject private var router = AppRouter()
    @StateObject private var networkMonitor = NetworkMonitor.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(router)
                .environmentObject(networkMonitor)
        }
    }
}

// 임시 ContentView — Task 4에서 ProfileSelectionView로 교체
struct ContentView: View {
    var body: some View {
        VStack(spacing: 20) {
            Text("🐶 SISO-Learn")
                .font(.largeTitle)
                .fontWeight(.bold)
            Text("쿠키와 함께 공부해요!")
                .font(.title2)
                .foregroundColor(.orange)
        }
    }
}
```

---

## 완료 기준 확인

| 항목 | 확인 방법 |
|------|-----------|
| 빌드 성공 | Xcode에서 `Cmd+B` → 에러 없음 |
| 시뮬레이터 실행 | iPad Air (5th gen) 시뮬레이터에서 "🐶 SISO-Learn" 텍스트 표시 |
| 폴더 구조 | Xcode 네비게이터에서 모든 그룹 확인 |
| GitHub 연결 | `git log` 로 초기 커밋 확인 |

---

## 다음 단계

Task 1 완료 후 **Task 2 (CoreData 스키마)** 와 **Task 3 (Keychain)** 을 병렬로 진행할 수 있다.
