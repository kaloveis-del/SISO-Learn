# Task 2 가이드: CoreData 스키마 및 데이터 레이어 구현

> **단계**: 1단계 (기반) | **선행 태스크**: Task 1 | **후행 태스크**: Task 4, Task 7

---

## 목표

앱의 모든 학습 데이터(프로필, 세션, 퀴즈 결과, 배지)를 저장하는 CoreData 스키마와 Repository 레이어를 구현한다.

---

## 체크리스트

- [x] 2.1 `SISOLearnModel.xcdatamodeld` 생성 및 4개 Entity 정의
- [x] 2.2 Entity 간 관계(Relationship) 설정
- [x] 2.3 `CoreDataStack.swift` 구현
- [x] 2.4 도메인 Swift 구조체 정의
- [x] 2.5 `ProfileRepository` 구현
- [x] 2.6 `SessionRepository` 구현
- [x] 2.7 CoreData 통합 테스트 작성

---

## 상세 구현 가이드

### 2.1 CoreData 모델 파일 생성

1. Xcode에서 `Core/CoreData/` 그룹 우클릭 → **New File**
2. **Core Data → Data Model** 선택
3. 파일명: `SISOLearnModel`

#### ProfileEntity 속성 설정

| Attribute | Type | Optional | Default |
|-----------|------|----------|---------|
| id | UUID | No | — |
| name | String | No | — |
| gradeLevel | String | No | — |
| avatarIndex | Integer 16 | No | 0 |
| createdAt | Date | No | — |
| lastActiveAt | Date | No | — |
| totalStudyMinutes | Integer 32 | No | 0 |
| currentStreak | Integer 16 | No | 0 |
| longestStreak | Integer 16 | No | 0 |

#### LearningSessionEntity 속성 설정

| Attribute | Type | Optional | Default |
|-----------|------|----------|---------|
| id | UUID | No | — |
| profileId | UUID | No | — |
| subject | String | No | — |
| difficulty | String | No | — |
| topic | String | No | — |
| startedAt | Date | No | — |
| completedAt | Date | Yes | — |
| totalQuizCount | Integer 16 | No | 0 |
| correctCount | Integer 16 | No | 0 |
| accuracyRate | Double | No | 0.0 |
| youtubeVideoId | String | Yes | — |
| durationSeconds | Integer 32 | No | 0 |

#### QuizResultEntity 속성 설정

| Attribute | Type | Optional | Default |
|-----------|------|----------|---------|
| id | UUID | No | — |
| sessionId | UUID | No | — |
| quizQuestion | String | No | — |
| userAnswer | String | No | — |
| isCorrect | Boolean | No | false |
| score | Integer 16 | No | 0 |
| hintUsedCount | Integer 16 | No | 0 |
| feedbackText | String | No | — |
| answeredAt | Date | No | — |
| timeSpentSeconds | Integer 32 | No | 0 |

#### AchievementEntity 속성 설정

| Attribute | Type | Optional | Default |
|-----------|------|----------|---------|
| id | UUID | No | — |
| profileId | UUID | No | — |
| badgeType | String | No | — |
| subject | String | Yes | — |
| earnedAt | Date | No | — |
| title | String | No | — |
| descriptionText | String | No | — |

---

### 2.2 Entity 관계 설정

CoreData 모델 에디터에서 Relationship 추가:

| Entity | Relationship | Destination | Inverse | Type |
|--------|-------------|-------------|---------|------|
| ProfileEntity | sessions | LearningSessionEntity | profile | To Many |
| ProfileEntity | achievements | AchievementEntity | profile | To Many |
| LearningSessionEntity | profile | ProfileEntity | sessions | To One |
| LearningSessionEntity | quizResults | QuizResultEntity | session | To Many |
| QuizResultEntity | session | LearningSessionEntity | quizResults | To One |
| AchievementEntity | profile | ProfileEntity | achievements | To One |

> ⚠️ **Delete Rule 설정**:
> - ProfileEntity.sessions → **Cascade** (프로필 삭제 시 세션도 삭제)
> - ProfileEntity.achievements → **Cascade**
> - LearningSessionEntity.quizResults → **Cascade**

---

### 2.3 `CoreDataStack.swift` 구현

경로: `Core/CoreData/CoreDataStack.swift`

```swift
import CoreData
import Foundation

final class CoreDataStack {

    static let shared = CoreDataStack()

    private init() {}

    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "SISOLearnModel")

        // Lightweight Migration 자동 설정
        let description = container.persistentStoreDescriptions.first
        description?.shouldMigrateStoreAutomatically = true
        description?.shouldInferMappingModelAutomatically = true

        container.loadPersistentStores { _, error in
            if let error = error {
                // 실제 앱에서는 사용자에게 오류 알림 후 재시작 유도
                fatalError("CoreData 로드 실패: \(error.localizedDescription)")
            }
        }
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        return container
    }()

    var viewContext: NSManagedObjectContext {
        persistentContainer.viewContext
    }

    /// 백그라운드 저장용 컨텍스트 (메인 스레드 블로킹 방지)
    func newBackgroundContext() -> NSManagedObjectContext {
        let context = persistentContainer.newBackgroundContext()
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        return context
    }

    /// 변경사항 저장
    func save(context: NSManagedObjectContext? = nil) throws {
        let ctx = context ?? viewContext
        guard ctx.hasChanges else { return }
        try ctx.save()
    }
}

// MARK: - 테스트용 인메모리 스택
extension CoreDataStack {
    static func inMemory() -> CoreDataStack {
        let stack = CoreDataStack()
        let description = NSPersistentStoreDescription()
        description.type = NSInMemoryStoreType
        stack.persistentContainer.persistentStoreDescriptions = [description]
        stack.persistentContainer.loadPersistentStores { _, error in
            if let error = error { fatalError("InMemory CoreData 실패: \(error)") }
        }
        return stack
    }
}
```

---

### 2.4 도메인 Swift 구조체 정의

경로: `Modules/Profile/Domain/Entities/Profile.swift`

```swift
import Foundation

struct Profile: Identifiable, Equatable {
    let id: UUID
    var name: String
    var gradeLevel: GradeLevel
    var avatarIndex: Int
    var createdAt: Date
    var lastActiveAt: Date
    var totalStudyMinutes: Int
    var currentStreak: Int
    var longestStreak: Int
}

// GradeLevel은 Task 5에서 AITutor 모듈에 정의되지만,
// Profile에서도 필요하므로 Core에 공통 정의
enum GradeLevel: String, Codable, CaseIterable {
    case grade5Elementary = "초등학교 5학년"
    case grade2Middle = "중학교 2학년"

    var vocabularyLevel: String {
        switch self {
        case .grade5Elementary:
            return "초등학교 5학년 수준. 한자어 최소화, 짧고 쉬운 문장 사용."
        case .grade2Middle:
            return "중학교 2학년 수준. 교과서 용어 포함, 개념 설명 포함."
        }
    }
}
```

경로: `Modules/Learning/Domain/Entities/LearningSession.swift`

```swift
import Foundation

struct LearningSession: Identifiable {
    let id: UUID
    let profileId: UUID
    var subject: Subject
    var difficulty: Difficulty
    var topic: String
    var startedAt: Date
    var completedAt: Date?
    var totalQuizCount: Int
    var correctCount: Int
    var accuracyRate: Double
    var youtubeVideoId: String?
    var durationSeconds: Int
}

enum Subject: String, Codable, CaseIterable {
    case math = "수학"
    case english = "영어"
    case science = "과학"
    case korean = "국어"
}

enum Difficulty: String, Codable, CaseIterable {
    case easy = "쉬움"
    case normal = "보통"
    case hard = "어려움"
}
```

경로: `Modules/Learning/Domain/Entities/QuizResult.swift`

```swift
import Foundation

struct QuizResult: Identifiable {
    let id: UUID
    let sessionId: UUID
    var quizQuestion: String
    var userAnswer: String
    var isCorrect: Bool
    var score: Int
    var hintUsedCount: Int
    var feedbackText: String
    var answeredAt: Date
    var timeSpentSeconds: Int
}
```

경로: `Modules/Progress/Domain/Entities/Achievement.swift`

```swift
import Foundation

struct Achievement: Identifiable {
    let id: UUID
    let profileId: UUID
    var badgeType: AchievementType
    var subject: Subject?
    var earnedAt: Date
    var title: String
    var descriptionText: String
}

enum AchievementType: String, CaseIterable {
    case mathMaster = "math_master"
    case englishMaster = "english_master"
    case scienceMaster = "science_master"
    case koreanMaster = "korean_master"
    case streakWeek = "streak_week"
    case firstSession = "first_session"
}
```

---

### 2.5 ProfileRepository 구현

경로: `Modules/Profile/Domain/Repositories/ProfileRepositoryProtocol.swift`

```swift
import Foundation

protocol ProfileRepositoryProtocol {
    func fetchAll() async throws -> [Profile]
    func create(name: String, gradeLevel: GradeLevel, avatarIndex: Int) async throws -> Profile
    func delete(id: UUID) async throws
    func updateLastActive(id: UUID) async throws
}
```

경로: `Modules/Profile/Data/Repositories/ProfileRepository.swift`

```swift
import CoreData
import Foundation

final class ProfileRepository: ProfileRepositoryProtocol {

    private let stack: CoreDataStack

    init(stack: CoreDataStack = .shared) {
        self.stack = stack
    }

    func fetchAll() async throws -> [Profile] {
        let context = stack.viewContext
        let request = ProfileEntity.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "lastActiveAt", ascending: false)]
        let entities = try context.fetch(request)
        return entities.map { $0.toDomain() }
    }

    func create(name: String, gradeLevel: GradeLevel, avatarIndex: Int) async throws -> Profile {
        let context = stack.viewContext
        let entity = ProfileEntity(context: context)
        entity.id = UUID()
        entity.name = name
        entity.gradeLevel = gradeLevel.rawValue
        entity.avatarIndex = Int16(avatarIndex)
        entity.createdAt = Date()
        entity.lastActiveAt = Date()
        entity.totalStudyMinutes = 0
        entity.currentStreak = 0
        entity.longestStreak = 0
        try stack.save()
        return entity.toDomain()
    }

    func delete(id: UUID) async throws {
        let context = stack.viewContext
        let request = ProfileEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        let entities = try context.fetch(request)
        entities.forEach { context.delete($0) }
        try stack.save()
    }

    func updateLastActive(id: UUID) async throws {
        let context = stack.viewContext
        let request = ProfileEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        if let entity = try context.fetch(request).first {
            entity.lastActiveAt = Date()
            try stack.save()
        }
    }
}

// MARK: - CoreData Entity → Domain 변환
extension ProfileEntity {
    func toDomain() -> Profile {
        Profile(
            id: id ?? UUID(),
            name: name ?? "",
            gradeLevel: GradeLevel(rawValue: gradeLevel ?? "") ?? .grade5Elementary,
            avatarIndex: Int(avatarIndex),
            createdAt: createdAt ?? Date(),
            lastActiveAt: lastActiveAt ?? Date(),
            totalStudyMinutes: Int(totalStudyMinutes),
            currentStreak: Int(currentStreak),
            longestStreak: Int(longestStreak)
        )
    }
}
```

---

### 2.6 SessionRepository 구현

경로: `Modules/Learning/Domain/Repositories/SessionRepositoryProtocol.swift`

```swift
import Foundation

protocol SessionRepositoryProtocol {
    func save(session: LearningSession, results: [QuizResult]) async throws
    func fetchRecent(profileId: UUID, limit: Int) async throws -> [LearningSession]
    func fetchSubjectStats(profileId: UUID) async throws -> [Subject: SubjectStat]
    func updateStreak(profileId: UUID) async throws
}

struct SubjectStat {
    let subject: Subject
    let totalSessions: Int
    let averageAccuracy: Double
    let totalQuizzes: Int
    let correctQuizzes: Int
}
```

경로: `Modules/Learning/Data/Repositories/SessionRepository.swift`

```swift
import CoreData
import Foundation

final class SessionRepository: SessionRepositoryProtocol {

    private let stack: CoreDataStack

    init(stack: CoreDataStack = .shared) {
        self.stack = stack
    }

    func save(session: LearningSession, results: [QuizResult]) async throws {
        let context = stack.newBackgroundContext()
        try await context.perform {
            // 세션 저장
            let sessionEntity = LearningSessionEntity(context: context)
            sessionEntity.id = session.id
            sessionEntity.profileId = session.profileId
            sessionEntity.subject = session.subject.rawValue
            sessionEntity.difficulty = session.difficulty.rawValue
            sessionEntity.topic = session.topic
            sessionEntity.startedAt = session.startedAt
            sessionEntity.completedAt = session.completedAt
            sessionEntity.totalQuizCount = Int16(session.totalQuizCount)
            sessionEntity.correctCount = Int16(session.correctCount)
            sessionEntity.accuracyRate = session.accuracyRate
            sessionEntity.youtubeVideoId = session.youtubeVideoId
            sessionEntity.durationSeconds = Int32(session.durationSeconds)

            // 퀴즈 결과 저장
            for result in results {
                let resultEntity = QuizResultEntity(context: context)
                resultEntity.id = result.id
                resultEntity.sessionId = result.sessionId
                resultEntity.quizQuestion = result.quizQuestion
                resultEntity.userAnswer = result.userAnswer
                resultEntity.isCorrect = result.isCorrect
                resultEntity.score = Int16(result.score)
                resultEntity.hintUsedCount = Int16(result.hintUsedCount)
                resultEntity.feedbackText = result.feedbackText
                resultEntity.answeredAt = result.answeredAt
                resultEntity.timeSpentSeconds = Int32(result.timeSpentSeconds)
                resultEntity.session = sessionEntity
            }

            try context.save()
        }
    }

    func fetchRecent(profileId: UUID, limit: Int = 20) async throws -> [LearningSession] {
        let context = stack.viewContext
        let request = LearningSessionEntity.fetchRequest()
        request.predicate = NSPredicate(format: "profileId == %@", profileId as CVarArg)
        request.sortDescriptors = [NSSortDescriptor(key: "startedAt", ascending: false)]
        request.fetchLimit = limit
        let entities = try context.fetch(request)
        return entities.map { $0.toDomain() }
    }

    func fetchSubjectStats(profileId: UUID) async throws -> [Subject: SubjectStat] {
        let sessions = try await fetchRecent(profileId: profileId, limit: 1000)
        var stats: [Subject: SubjectStat] = [:]
        for subject in Subject.allCases {
            let subjectSessions = sessions.filter { $0.subject == subject }
            guard !subjectSessions.isEmpty else { continue }
            let avgAccuracy = subjectSessions.map(\.accuracyRate).reduce(0, +) / Double(subjectSessions.count)
            let totalQuizzes = subjectSessions.map(\.totalQuizCount).reduce(0, +)
            let correctQuizzes = subjectSessions.map(\.correctCount).reduce(0, +)
            stats[subject] = SubjectStat(
                subject: subject,
                totalSessions: subjectSessions.count,
                averageAccuracy: avgAccuracy,
                totalQuizzes: totalQuizzes,
                correctQuizzes: correctQuizzes
            )
        }
        return stats
    }

    func updateStreak(profileId: UUID) async throws {
        let context = stack.viewContext
        let request = ProfileEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", profileId as CVarArg)
        guard let profile = try context.fetch(request).first else { return }

        let lastActive = profile.lastActiveAt ?? Date()
        if Calendar.current.isDateInYesterday(lastActive) {
            // 연속 학습 유지
            profile.currentStreak += 1
        } else if !Calendar.current.isDateInToday(lastActive) {
            // 스트릭 초기화
            profile.currentStreak = 1
        }
        // 최장 스트릭 업데이트
        if profile.currentStreak > profile.longestStreak {
            profile.longestStreak = profile.currentStreak
        }
        profile.lastActiveAt = Date()
        try stack.save()
    }
}

extension LearningSessionEntity {
    func toDomain() -> LearningSession {
        LearningSession(
            id: id ?? UUID(),
            profileId: profileId ?? UUID(),
            subject: Subject(rawValue: subject ?? "") ?? .math,
            difficulty: Difficulty(rawValue: difficulty ?? "") ?? .normal,
            topic: topic ?? "",
            startedAt: startedAt ?? Date(),
            completedAt: completedAt,
            totalQuizCount: Int(totalQuizCount),
            correctCount: Int(correctCount),
            accuracyRate: accuracyRate,
            youtubeVideoId: youtubeVideoId,
            durationSeconds: Int(durationSeconds)
        )
    }
}
```

---

### 2.7 CoreData 통합 테스트 작성

경로: `Tests/IntegrationTests/CoreDataIntegrationTests.swift`

```swift
import XCTest
import CoreData
@testable import SISOLearn

final class CoreDataIntegrationTests: XCTestCase {

    var stack: CoreDataStack!
    var profileRepo: ProfileRepository!

    override func setUp() {
        super.setUp()
        stack = CoreDataStack.inMemory()
        profileRepo = ProfileRepository(stack: stack)
    }

    // 프로필 생성 및 조회 테스트
    func test_createAndFetchProfile() async throws {
        let profile = try await profileRepo.create(
            name: "테스트", gradeLevel: .grade5Elementary, avatarIndex: 0
        )
        let profiles = try await profileRepo.fetchAll()
        XCTAssertEqual(profiles.count, 1)
        XCTAssertEqual(profiles.first?.name, "테스트")
        XCTAssertEqual(profiles.first?.id, profile.id)
    }

    // 프로필 삭제 테스트
    func test_deleteProfile() async throws {
        let profile = try await profileRepo.create(
            name: "삭제테스트", gradeLevel: .grade2Middle, avatarIndex: 1
        )
        try await profileRepo.delete(id: profile.id)
        let profiles = try await profileRepo.fetchAll()
        XCTAssertTrue(profiles.isEmpty)
    }

    // 세션 저장 및 조회 테스트
    func test_saveAndFetchSession() async throws {
        let profile = try await profileRepo.create(
            name: "세션테스트", gradeLevel: .grade5Elementary, avatarIndex: 0
        )
        let sessionRepo = SessionRepository(stack: stack)
        let session = LearningSession(
            id: UUID(), profileId: profile.id,
            subject: .math, difficulty: .normal, topic: "분수",
            startedAt: Date(), completedAt: Date(),
            totalQuizCount: 5, correctCount: 4, accuracyRate: 0.8,
            youtubeVideoId: nil, durationSeconds: 300
        )
        try await sessionRepo.save(session: session, results: [])
        let sessions = try await sessionRepo.fetchRecent(profileId: profile.id, limit: 10)
        XCTAssertEqual(sessions.count, 1)
        XCTAssertEqual(sessions.first?.accuracyRate, 0.8, accuracy: 0.001)
    }
}
```

---

## 완료 기준 확인

| 항목 | 확인 방법 |
|------|-----------|
| CoreData 모델 | Xcode에서 `.xcdatamodeld` 열어 4개 Entity 확인 |
| 관계 설정 | 각 Entity의 Relationships 탭에서 확인 |
| 통합 테스트 | `Cmd+U` → `CoreDataIntegrationTests` 모두 통과 |

---

## 다음 단계

Task 2 완료 후 **Task 4 (프로필 관리 모듈)** 로 진행한다.
Task 3 (Keychain)은 Task 2와 병렬로 진행 가능하다.
