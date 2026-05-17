# Task 3 가이드: Keychain 보안 서비스 및 설정 화면 구현

> **단계**: 1단계 (기반) | **선행 태스크**: Task 1 | **후행 태스크**: Task 5, Task 7

---

## 목표

Gemini API Key를 iOS Keychain에 안전하게 저장·조회·삭제하는 서비스와 설정 화면을 구현한다. API Key는 절대 UserDefaults나 로그에 저장되어서는 안 된다.

---

## 체크리스트

- [x] 3.1 `KeychainService.swift` 구현
- [x] 3.2 `ManageAPIKeyUseCase.swift` 구현
- [x] 3.3 `SettingsViewModel.swift` 구현
- [x] 3.4 `SettingsView.swift` 구현
- [x] 3.5 `KeychainServiceTests.swift` 작성

---

## 상세 구현 가이드

### 3.1 `KeychainService.swift` 구현

경로: `Modules/Settings/Data/KeychainService.swift`

```swift
import Security
import Foundation

final class KeychainService {

    // MARK: - API Key 저장
    func save(apiKey: String) throws {
        guard let data = apiKey.data(using: .utf8) else {
            throw KeychainError.encodingFailed
        }
        // 기존 항목 삭제 후 새로 저장 (업데이트 방식)
        try? delete()

        let query: [String: Any] = [
            kSecClass as String:            kSecClassGenericPassword,
            kSecAttrService as String:      KeychainKeys.service,
            kSecAttrAccount as String:      KeychainKeys.geminiAPIKey,
            kSecValueData as String:        data,
            // 기기 잠금 해제 상태에서만 접근, iCloud 백업 제외
            kSecAttrAccessible as String:   kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]

        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw KeychainError.saveFailed(status)
        }
    }

    // MARK: - API Key 조회
    func load() throws -> String {
        let query: [String: Any] = [
            kSecClass as String:        kSecClassGenericPassword,
            kSecAttrService as String:  KeychainKeys.service,
            kSecAttrAccount as String:  KeychainKeys.geminiAPIKey,
            kSecReturnData as String:   true,
            kSecMatchLimit as String:   kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess,
              let data = result as? Data,
              let apiKey = String(data: data, encoding: .utf8) else {
            throw KeychainError.notFound
        }
        return apiKey
    }

    // MARK: - API Key 존재 여부 확인
    func hasAPIKey() -> Bool {
        (try? load()) != nil
    }

    // MARK: - API Key 삭제
    func delete() throws {
        let query: [String: Any] = [
            kSecClass as String:        kSecClassGenericPassword,
            kSecAttrService as String:  KeychainKeys.service,
            kSecAttrAccount as String:  KeychainKeys.geminiAPIKey
        ]
        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.deleteFailed(status)
        }
    }
}

// MARK: - 에러 타입
enum KeychainError: LocalizedError {
    case encodingFailed
    case saveFailed(OSStatus)
    case notFound
    case deleteFailed(OSStatus)

    var errorDescription: String? {
        switch self {
        case .encodingFailed:           return "API 키 인코딩에 실패했어요"
        case .saveFailed(let status):   return "저장 실패 (코드: \(status))"
        case .notFound:                 return "저장된 API 키가 없어요"
        case .deleteFailed(let status): return "삭제 실패 (코드: \(status))"
        }
    }
}
```

---

### 3.2 `ManageAPIKeyUseCase.swift` 구현

경로: `Modules/Settings/Domain/UseCases/ManageAPIKeyUseCase.swift`

```swift
import Foundation

final class ManageAPIKeyUseCase {

    private let keychainService: KeychainService

    init(keychainService: KeychainService = KeychainService()) {
        self.keychainService = keychainService
    }

    func save(apiKey: String) throws {
        try keychainService.save(apiKey: apiKey)
    }

    func load() throws -> String {
        try keychainService.load()
    }

    func hasAPIKey() -> Bool {
        keychainService.hasAPIKey()
    }

    func delete() throws {
        try keychainService.delete()
    }

    /// Gemini API Key 형식 검증: "AIza"로 시작하는 39자
    func isValidFormat(_ key: String) -> Bool {
        key.hasPrefix("AIza") && key.count == 39
    }
}
```

---

### 3.3 `SettingsViewModel.swift` 구현

경로: `Modules/Settings/Presentation/ViewModels/SettingsViewModel.swift`

```swift
import SwiftUI

@MainActor
final class SettingsViewModel: ObservableObject {

    // MARK: - 상태
    @Published var apiKeyInput: String = ""
    @Published var isAPIKeyVisible: Bool = false
    @Published var isAPIKeyValid: Bool = false
    @Published var isSaving: Bool = false
    @Published var hasStoredAPIKey: Bool = false
    @Published var alertMessage: String?
    @Published var showAlert: Bool = false

    enum SaveResult { case success, failure(String) }
    @Published var saveResult: SaveResult?

    // MARK: - 의존성
    private let useCase: ManageAPIKeyUseCase

    init(useCase: ManageAPIKeyUseCase = ManageAPIKeyUseCase()) {
        self.useCase = useCase
    }

    // MARK: - 액션

    func onAppear() {
        hasStoredAPIKey = useCase.hasAPIKey()
    }

    func validateFormat() {
        isAPIKeyValid = useCase.isValidFormat(apiKeyInput)
    }

    func saveAPIKey() {
        guard isAPIKeyValid else { return }
        isSaving = true
        do {
            try useCase.save(apiKey: apiKeyInput)
            hasStoredAPIKey = true
            apiKeyInput = ""
            saveResult = .success
            alertMessage = "API 키가 저장됐어요! 🐶"
            showAlert = true
        } catch {
            saveResult = .failure(error.localizedDescription)
            alertMessage = error.localizedDescription
            showAlert = true
        }
        isSaving = false
    }

    func deleteAPIKey() {
        do {
            try useCase.delete()
            hasStoredAPIKey = false
            alertMessage = "API 키가 삭제됐어요"
            showAlert = true
        } catch {
            alertMessage = error.localizedDescription
            showAlert = true
        }
    }
}
```

---

### 3.4 `SettingsView.swift` 구현

경로: `Modules/Settings/Presentation/Views/SettingsView.swift`

```swift
import SwiftUI

struct SettingsView: View {

    @StateObject private var viewModel = SettingsViewModel()

    var body: some View {
        NavigationStack {
            Form {
                // MARK: - API Key 섹션
                Section {
                    apiKeyInputSection
                } header: {
                    Text("Gemini API Key")
                } footer: {
                    Text("Google AI Studio(aistudio.google.com)에서 무료로 발급받을 수 있어요.")
                        .font(.caption)
                }

                // MARK: - 저장된 키 상태
                if viewModel.hasStoredAPIKey {
                    Section {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("API 키가 저장되어 있어요")
                            Spacer()
                            Button("삭제", role: .destructive) {
                                viewModel.deleteAPIKey()
                            }
                        }
                    }
                }

                // MARK: - 앱 정보
                Section("앱 정보") {
                    LabeledContent("버전", value: "1.0.0")
                    LabeledContent("AI 모델", value: "Gemini 2.0 Flash")
                }
            }
            .navigationTitle("설정")
            .onAppear { viewModel.onAppear() }
            .alert("알림", isPresented: $viewModel.showAlert) {
                Button("확인") {}
            } message: {
                Text(viewModel.alertMessage ?? "")
            }
        }
    }

    // MARK: - API Key 입력 영역
    @ViewBuilder
    private var apiKeyInputSection: some View {
        HStack {
            Group {
                if viewModel.isAPIKeyVisible {
                    TextField("AIza...", text: $viewModel.apiKeyInput)
                } else {
                    SecureField("AIza...", text: $viewModel.apiKeyInput)
                }
            }
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .onChange(of: viewModel.apiKeyInput) { _ in
                viewModel.validateFormat()
            }

            Button {
                viewModel.isAPIKeyVisible.toggle()
            } label: {
                Image(systemName: viewModel.isAPIKeyVisible ? "eye.slash" : "eye")
                    .foregroundColor(.secondary)
            }
        }

        // 형식 검증 표시
        if !viewModel.apiKeyInput.isEmpty {
            HStack(spacing: 6) {
                Image(systemName: viewModel.isAPIKeyValid ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundColor(viewModel.isAPIKeyValid ? .green : .red)
                Text(viewModel.isAPIKeyValid ? "올바른 형식이에요" : "'AIza'로 시작하는 39자여야 해요")
                    .font(.caption)
                    .foregroundColor(viewModel.isAPIKeyValid ? .green : .red)
            }
        }

        Button {
            viewModel.saveAPIKey()
        } label: {
            HStack {
                if viewModel.isSaving {
                    ProgressView().scaleEffect(0.8)
                }
                Text("저장하기")
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .disabled(!viewModel.isAPIKeyValid || viewModel.isSaving)
        // 접근성: 최소 터치 영역 44pt
        .frame(minHeight: 44)
    }
}
```

---

### 3.5 `KeychainServiceTests.swift` 작성

경로: `Tests/UnitTests/Settings/KeychainServiceTests.swift`

```swift
import XCTest
@testable import SISOLearn

final class KeychainServiceTests: XCTestCase {

    var sut: KeychainService!

    override func setUp() {
        super.setUp()
        sut = KeychainService()
        // 테스트 전 기존 키 삭제
        try? sut.delete()
    }

    override func tearDown() {
        try? sut.delete()
        super.tearDown()
    }

    func test_saveAndLoad_roundTrip() throws {
        let testKey = "AIzaTestKey1234567890123456789012345"
        try sut.save(apiKey: testKey)
        let loaded = try sut.load()
        XCTAssertEqual(loaded, testKey)
    }

    func test_hasAPIKey_returnsTrueAfterSave() throws {
        XCTAssertFalse(sut.hasAPIKey())
        try sut.save(apiKey: "AIzaTestKey1234567890123456789012345")
        XCTAssertTrue(sut.hasAPIKey())
    }

    func test_delete_removesKey() throws {
        try sut.save(apiKey: "AIzaTestKey1234567890123456789012345")
        try sut.delete()
        XCTAssertFalse(sut.hasAPIKey())
    }

    func test_load_throwsWhenNoKey() {
        XCTAssertThrowsError(try sut.load()) { error in
            XCTAssertEqual(error as? KeychainError, .notFound)
        }
    }

    func test_isValidFormat_correctKey() {
        let useCase = ManageAPIKeyUseCase()
        // 39자 AIza 시작 키
        XCTAssertTrue(useCase.isValidFormat("AIzaTestKey1234567890123456789012345"))
        // 짧은 키
        XCTAssertFalse(useCase.isValidFormat("AIzaShort"))
        // 잘못된 접두사
        XCTAssertFalse(useCase.isValidFormat("sk-TestKey1234567890123456789012345"))
    }
}

extension KeychainError: Equatable {
    public static func == (lhs: KeychainError, rhs: KeychainError) -> Bool {
        switch (lhs, rhs) {
        case (.notFound, .notFound): return true
        case (.encodingFailed, .encodingFailed): return true
        default: return false
        }
    }
}
```

---

## 완료 기준 확인

| 항목 | 확인 방법 |
|------|-----------|
| API Key 저장 | SettingsView에서 키 입력 후 저장 → 앱 재시작 후 `hasStoredAPIKey == true` |
| 형식 검증 | "AIza" 미시작 또는 39자 미만 입력 시 저장 버튼 비활성화 |
| 단위 테스트 | `Cmd+U` → `KeychainServiceTests` 모두 통과 |
| 보안 확인 | UserDefaults에 API Key 없음 (`UserDefaults.standard.dictionaryRepresentation()` 확인) |

---

## 다음 단계

Task 3 완료 후 **Task 5 (AI 연동 모듈)** 로 진행한다.
`AppRouter`에서 API Key 없을 때 SettingsView로 자동 이동하는 로직은 Task 7에서 연결한다.
