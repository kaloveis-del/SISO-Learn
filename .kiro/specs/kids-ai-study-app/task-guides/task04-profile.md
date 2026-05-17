# Task 4 가이드: 프로필 관리 모듈 구현

> **단계**: 2단계 (AI 연동) | **선행 태스크**: Task 2 | **후행 태스크**: Task 7

---

## 목표

최대 5개의 사용자 프로필을 생성·선택·삭제하는 화면을 구현한다. 각 프로필은 이름, 학년, 아바타를 가지며 학습 기록이 분리된다.

---

## 체크리스트

- [x] 4.1 `ManageProfileUseCase.swift` 구현
- [x] 4.2 `ProfileViewModel.swift` 구현
- [x] 4.3 `ProfileSelectionView.swift` 구현
- [x] 4.4 `ProfileCreationView.swift` 구현
- [ ] 4.5 단위 테스트 작성
- [ ] 4.6 속성 기반 테스트 작성

---

## 상세 구현 가이드

### 4.1 `ManageProfileUseCase.swift` 구현

경로: `Modules/Profile/Domain/UseCases/ManageProfileUseCase.swift`

```swift
import Foundation

final class ManageProfileUseCase {

    private let repository: ProfileRepositoryProtocol

    init(repository: ProfileRepositoryProtocol) {
        self.repository = repository
    }

    func fetchAll() async throws -> [Profile] {
        try await repository.fetchAll()
    }

    func create(name: String, gradeLevel: GradeLevel, avatarIndex: Int) async throws -> Profile {
        // CP-5: 프로필 수 제한 (최대 5개)
        let existing = try await repository.fetchAll()
        guard existing.count < AppConstants.maxProfileCount else {
            throw ProfileError.maxProfilesReached
        }
        guard !name.isBlank else {
            throw ProfileError.invalidName
        }
        return try await repository.create(name: name.trimmingCharacters(in: .whitespaces),
                                           gradeLevel: gradeLevel,
                                           avatarIndex: avatarIndex)
    }

    func delete(profileId: UUID) async throws {
        try await repository.delete(id: profileId)
    }

    func updateLastActive(profileId: UUID) async throws {
        try await repository.updateLastActive(id: profileId)
    }
}

enum ProfileError: LocalizedError {
    case maxProfilesReached
    case invalidName

    var errorDescription: String? {
        switch self {
        case .maxProfilesReached: return "프로필은 최대 5개까지 만들 수 있어요"
        case .invalidName: return "이름을 입력해주세요"
        }
    }
}
```

---

### 4.2 `ProfileViewModel.swift` 구현

경로: `Modules/Profile/Presentation/ViewModels/ProfileViewModel.swift`

```swift
import SwiftUI

@MainActor
final class ProfileViewModel: ObservableObject {

    // MARK: - 상태
    @Published var profiles: [Profile] = []
    @Published var selectedProfile: Profile?
    @Published var isCreatingProfile = false
    @Published var newProfileName = ""
    @Published var newProfileGrade: GradeLevel = .grade5Elementary
    @Published var newProfileAvatarIndex = 0
    @Published var isLoading = false
    @Published var errorMessage: String?

    // MARK: - 계산 속성
    var canAddProfile: Bool { profiles.count < AppConstants.maxProfileCount }
    var isNewProfileValid: Bool { !newProfileName.isBlank }

    // MARK: - 의존성
    private let useCase: ManageProfileUseCase

    init(useCase: ManageProfileUseCase) {
        self.useCase = useCase
    }

    // MARK: - 액션

    func loadProfiles() {
        isLoading = true
        Task {
            do {
                profiles = try await useCase.fetchAll()
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }

    func selectProfile(_ profile: Profile) {
        selectedProfile = profile
        Task { try? await useCase.updateLastActive(profileId: profile.id) }
    }

    func createProfile() {
        guard isNewProfileValid else { return }
        Task {
            do {
                let profile = try await useCase.create(
                    name: newProfileName,
                    gradeLevel: newProfileGrade,
                    avatarIndex: newProfileAvatarIndex
                )
                profiles.append(profile)
                resetForm()
                isCreatingProfile = false
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    func deleteProfile(_ profile: Profile) {
        Task {
            do {
                try await useCase.delete(profileId: profile.id)
                profiles.removeAll { $0.id == profile.id }
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    private func resetForm() {
        newProfileName = ""
        newProfileGrade = .grade5Elementary
        newProfileAvatarIndex = 0
    }
}
```

---

### 4.3 `ProfileSelectionView.swift` 구현

경로: `Modules/Profile/Presentation/Views/ProfileSelectionView.swift`

```swift
import SwiftUI

struct ProfileSelectionView: View {

    @StateObject private var viewModel: ProfileViewModel
    @EnvironmentObject private var router: AppRouter

    // 아바타 이모지 목록 (이미지 에셋 없을 때 임시 사용)
    private let avatarEmojis = ["🐶", "🐱", "🐻", "🦊", "🐼", "🐨", "🐯", "🦁"]

    init(useCase: ManageProfileUseCase) {
        _viewModel = StateObject(wrappedValue: ProfileViewModel(useCase: useCase))
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // 쿠키 인사 영역 (Task 6에서 CookieBubbleView로 교체)
                cookieGreeting

                // 프로필 그리드
                profileGrid

                // 새 프로필 추가 버튼
                if viewModel.canAddProfile {
                    addProfileButton
                }
            }
            .padding()
            .navigationTitle("누가 공부할 거야? 🐶")
            .onAppear { viewModel.loadProfiles() }
            .sheet(isPresented: $viewModel.isCreatingProfile) {
                ProfileCreationView(viewModel: viewModel)
            }
            .alert("오류", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("확인") { viewModel.errorMessage = nil }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
        }
    }

    // MARK: - 쿠키 인사 (임시 — Task 6에서 교체)
    private var cookieGreeting: some View {
        HStack(spacing: 12) {
            Text("🐶")
                .font(.system(size: 56))
            VStack(alignment: .leading) {
                Text("안녕! 나는 쿠키야!")
                    .font(.title2).fontWeight(.bold)
                Text("오늘도 같이 공부해볼까? 멍멍!")
                    .font(.body).foregroundColor(.secondary)
            }
            Spacer()
        }
        .padding()
        .background(Color.orange.opacity(0.1))
        .cornerRadius(16)
    }

    // MARK: - 프로필 그리드
    private var profileGrid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 3),
                  spacing: 16) {
            ForEach(viewModel.profiles) { profile in
                ProfileCardView(profile: profile, avatarEmojis: avatarEmojis) {
                    viewModel.selectProfile(profile)
                    router.navigate(to: .home)
                } onDelete: {
                    viewModel.deleteProfile(profile)
                }
            }
        }
    }

    // MARK: - 추가 버튼
    private var addProfileButton: some View {
        Button {
            viewModel.isCreatingProfile = true
        } label: {
            Label("새 프로필 추가", systemImage: "plus.circle.fill")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
        }
        .buttonStyle(.borderedProminent)
        .tint(.orange)
    }
}

// MARK: - 프로필 카드
struct ProfileCardView: View {
    let profile: Profile
    let avatarEmojis: [String]
    let onSelect: () -> Void
    let onDelete: () -> Void

    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: 8) {
                Text(avatarEmojis[safe: profile.avatarIndex] ?? "🐶")
                    .font(.system(size: 48))
                Text(profile.name)
                    .font(.headline)
                    .lineLimit(1)
                Text(profile.gradeLevel.rawValue)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("삭제", systemImage: "trash")
            }
        }
        // 접근성
        .accessibilityLabel("\(profile.name), \(profile.gradeLevel.rawValue)")
        .accessibilityHint("탭하면 이 프로필로 학습을 시작해요")
    }
}
```

---

### 4.4 `ProfileCreationView.swift` 구현

경로: `Modules/Profile/Presentation/Views/ProfileCreationView.swift`

```swift
import SwiftUI

struct ProfileCreationView: View {

    @ObservedObject var viewModel: ProfileViewModel
    @Environment(\.dismiss) private var dismiss

    private let avatarEmojis = ["🐶", "🐱", "🐻", "🦊", "🐼", "🐨", "🐯", "🦁"]

    var body: some View {
        NavigationStack {
            Form {
                // 이름 입력
                Section("이름") {
                    TextField("이름을 입력해줘", text: $viewModel.newProfileName)
                        .textInputAutocapitalization(.never)
                }

                // 학년 선택
                Section("학년") {
                    Picker("학년", selection: $viewModel.newProfileGrade) {
                        ForEach(GradeLevel.allCases, id: \.self) { grade in
                            Text(grade.rawValue).tag(grade)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                // 아바타 선택
                Section("아바타") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4),
                              spacing: 12) {
                        ForEach(avatarEmojis.indices, id: \.self) { index in
                            Button {
                                viewModel.newProfileAvatarIndex = index
                            } label: {
                                Text(avatarEmojis[index])
                                    .font(.system(size: 40))
                                    .frame(width: 60, height: 60)
                                    .background(
                                        viewModel.newProfileAvatarIndex == index
                                            ? Color.orange.opacity(0.3)
                                            : Color.clear
                                    )
                                    .cornerRadius(12)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
            .navigationTitle("새 프로필 만들기")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("완료") {
                        viewModel.createProfile()
                    }
                    .disabled(!viewModel.isNewProfileValid)
                    .fontWeight(.semibold)
                }
            }
        }
    }
}
```

---

### 4.5 단위 테스트 작성

경로: `Tests/UnitTests/Profile/ProfileViewModelTests.swift`

```swift
import XCTest
@testable import SISOLearn

@MainActor
final class ProfileViewModelTests: XCTestCase {

    var sut: ProfileViewModel!
    var mockRepo: MockProfileRepository!

    override func setUp() {
        super.setUp()
        mockRepo = MockProfileRepository()
        let useCase = ManageProfileUseCase(repository: mockRepo)
        sut = ProfileViewModel(useCase: useCase)
    }

    func test_loadProfiles_populatesProfiles() async {
        mockRepo.profilesToReturn = [Profile.mock()]
        sut.loadProfiles()
        try? await Task.sleep(nanoseconds: 100_000_000)
        XCTAssertEqual(sut.profiles.count, 1)
    }

    func test_canAddProfile_falseWhenFiveProfiles() {
        sut.profiles = (0..<5).map { _ in Profile.mock() }
        XCTAssertFalse(sut.canAddProfile)
    }

    func test_isNewProfileValid_falseWhenBlank() {
        sut.newProfileName = "   "
        XCTAssertFalse(sut.isNewProfileValid)
    }
}

// MARK: - Mock
final class MockProfileRepository: ProfileRepositoryProtocol {
    var profilesToReturn: [Profile] = []
    var createCallCount = 0

    func fetchAll() async throws -> [Profile] { profilesToReturn }
    func create(name: String, gradeLevel: GradeLevel, avatarIndex: Int) async throws -> Profile {
        createCallCount += 1
        return Profile.mock(name: name, gradeLevel: gradeLevel)
    }
    func delete(id: UUID) async throws { profilesToReturn.removeAll { $0.id == id } }
    func updateLastActive(id: UUID) async throws {}
}

extension Profile {
    static func mock(name: String = "테스트", gradeLevel: GradeLevel = .grade5Elementary) -> Profile {
        Profile(id: UUID(), name: name, gradeLevel: gradeLevel, avatarIndex: 0,
                createdAt: Date(), lastActiveAt: Date(),
                totalStudyMinutes: 0, currentStreak: 0, longestStreak: 0)
    }
}
```

---

### 4.6 속성 기반 테스트 작성

경로: `Tests/PropertyTests/ProfileLimitPropertyTests.swift`

```swift
import Testing
@testable import SISOLearn

struct ProfileLimitPropertyTests {

    // CP-5: 프로필 수는 항상 5개 이하여야 한다
    @Test("프로필 수 제한 속성 테스트", arguments: [1, 3, 5, 6, 7, 10])
    func profileCountNeverExceedsFive(attemptCount: Int) async throws {
        let repo = MockProfileRepository()
        let useCase = ManageProfileUseCase(repository: repo)

        for i in 1...attemptCount {
            try? await useCase.create(name: "테스트\(i)",
                                      gradeLevel: .grade5Elementary,
                                      avatarIndex: 0)
        }

        let profiles = try await useCase.fetchAll()
        #expect(profiles.count <= 5)
    }
}
```

---

## 완료 기준 확인

| 항목 | 확인 방법 |
|------|-----------|
| 프로필 생성 | 이름 + 학년 + 아바타 선택 후 완료 → 카드 표시 |
| 5개 제한 | 5개 생성 후 추가 버튼 비활성화 확인 |
| 프로필 삭제 | 카드 롱프레스 → 삭제 메뉴 → 카드 제거 |
| 단위 테스트 | `Cmd+U` → `ProfileViewModelTests` 통과 |
| 속성 테스트 | `ProfileLimitPropertyTests` 통과 |

---

## 다음 단계

Task 4 완료 후 **Task 7 (대화형 학습 세션)** 로 진행한다.
Task 5 (AI 연동)와 Task 6 (쿠키 캐릭터)가 완료된 후 Task 7을 시작한다.
