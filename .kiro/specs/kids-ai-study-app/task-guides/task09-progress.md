# Task 9 가이드: 학습 진행 현황 (Progress) 구현

> **단계**: 5단계 (확장) | **선행 태스크**: Task 7 | **후행 태스크**: Task 11

---

## 목표

학습 세션 완료 후 정답률, 연속 학습 스트릭, 과목별 통계, 성취 배지를 표시하는 Progress 화면을 구현한다.

---

## 체크리스트

- [ ] 9.1 `FetchAchievementsUseCase.swift` 구현
- [ ] 9.2 스트릭 업데이트 로직 확인 (Task 7의 SaveProgressUseCase에 포함)
- [ ] 9.3 배지 자동 부여 로직 구현
- [ ] 9.4 `ProgressViewModel.swift` 구현
- [ ] 9.5 `ProgressView.swift` 구현
- [ ] 9.6 `ProgressViewModelTests.swift` 작성

---

## 상세 구현 가이드

### 9.1 `FetchAchievementsUseCase.swift`

경로: `Modules/Progress/Domain/UseCases/FetchAchievementsUseCase.swift`

```swift
import Foundation

final class FetchAchievementsUseCase {
    private let sessionRepo: SessionRepositoryProtocol
    private let stack: CoreDataStack

    init(sessionRepo: SessionRepositoryProtocol, stack: CoreDataStack = .shared) {
        self.sessionRepo = sessionRepo
        self.stack = stack
    }

    func fetchRecentSessions(profileId: UUID, limit: Int = 20) async throws -> [LearningSession] {
        try await sessionRepo.fetchRecent(profileId: profileId, limit: limit)
    }

    func fetchSubjectStats(profileId: UUID) async throws -> [Subject: SubjectStat] {
        try await sessionRepo.fetchSubjectStats(profileId: profileId)
    }

    func fetchAchievements(profileId: UUID) async throws -> [Achievement] {
        let context = stack.viewContext
        let request = AchievementEntity.fetchRequest()
        request.predicate = NSPredicate(format: "profileId == %@", profileId as CVarArg)
        request.sortDescriptors = [NSSortDescriptor(key: "earnedAt", ascending: false)]
        let entities = try context.fetch(request)
        return entities.map { entity in
            Achievement(
                id: entity.id ?? UUID(),
                profileId: entity.profileId ?? UUID(),
                badgeType: AchievementType(rawValue: entity.badgeType ?? "") ?? .firstSession,
                subject: Subject(rawValue: entity.subject ?? ""),
                earnedAt: entity.earnedAt ?? Date(),
                title: entity.title ?? "",
                descriptionText: entity.descriptionText ?? ""
            )
        }
    }
}
```

### 9.3 배지 자동 부여 로직

`SaveProgressUseCase`에 배지 확인 로직을 추가한다:

```swift
// SaveProgressUseCase.execute() 내부에 추가
private func checkAndAwardBadge(profileId: UUID, subject: Subject,
                                 stats: [Subject: SubjectStat]) async throws {
    guard let stat = stats[subject],
          stat.averageAccuracy >= AppConstants.achievementAccuracyThreshold else { return }

    let context = CoreDataStack.shared.viewContext
    // 이미 해당 과목 배지가 있는지 확인
    let request = AchievementEntity.fetchRequest()
    request.predicate = NSPredicate(
        format: "profileId == %@ AND subject == %@",
        profileId as CVarArg, subject.rawValue)
    let existing = try context.fetch(request)
    guard existing.isEmpty else { return }

    // 배지 생성
    let badge = AchievementEntity(context: context)
    badge.id = UUID()
    badge.profileId = profileId
    badge.badgeType = AchievementType.badgeType(for: subject).rawValue
    badge.subject = subject.rawValue
    badge.earnedAt = Date()
    badge.title = "\(subject.rawValue) 마스터 🏆"
    badge.descriptionText = "\(subject.rawValue) 정답률 80% 달성!"
    try CoreDataStack.shared.save()
}

extension AchievementType {
    static func badgeType(for subject: Subject) -> AchievementType {
        switch subject {
        case .math:    return .mathMaster
        case .english: return .englishMaster
        case .science: return .scienceMaster
        case .korean:  return .koreanMaster
        }
    }
}
```

### 9.4 `ProgressViewModel.swift`

경로: `Modules/Progress/Presentation/ViewModels/ProgressViewModel.swift`

```swift
import SwiftUI

@MainActor
final class ProgressViewModel: ObservableObject {

    @Published var recentSessions: [LearningSession] = []
    @Published var achievements: [Achievement] = []
    @Published var subjectStats: [Subject: SubjectStat] = [:]
    @Published var currentStreak: Int = 0
    @Published var longestStreak: Int = 0
    @Published var totalStudyMinutes: Int = 0
    @Published var isLoading = false
    @Published var selectedSubjectFilter: Subject? = nil

    var filteredSessions: [LearningSession] {
        guard let filter = selectedSubjectFilter else { return recentSessions }
        return recentSessions.filter { $0.subject == filter }
    }

    var overallAccuracy: Double {
        guard !recentSessions.isEmpty else { return 0 }
        return recentSessions.map(\.accuracyRate).reduce(0, +) / Double(recentSessions.count)
    }

    private let useCase: FetchAchievementsUseCase
    private let profile: Profile

    init(profile: Profile, useCase: FetchAchievementsUseCase) {
        self.profile = profile
        self.useCase = useCase
    }

    func loadProgress() {
        isLoading = true
        Task {
            async let sessions = useCase.fetchRecentSessions(profileId: profile.id)
            async let badges  = useCase.fetchAchievements(profileId: profile.id)
            async let stats   = useCase.fetchSubjectStats(profileId: profile.id)

            recentSessions  = (try? await sessions) ?? []
            achievements    = (try? await badges)   ?? []
            subjectStats    = (try? await stats)    ?? [:]
            currentStreak   = profile.currentStreak
            longestStreak   = profile.longestStreak
            totalStudyMinutes = profile.totalStudyMinutes
            isLoading = false
        }
    }
}
```

### 9.5 `ProgressView.swift`

경로: `Modules/Progress/Presentation/Views/ProgressView.swift`

```swift
import SwiftUI

struct ProgressView: View {
    @StateObject private var viewModel: ProgressViewModel

    init(profile: Profile, useCase: FetchAchievementsUseCase) {
        _viewModel = StateObject(wrappedValue: ProgressViewModel(profile: profile, useCase: useCase))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // 스트릭 카드
                streakCard

                // 전체 정답률
                accuracyCard

                // 과목별 통계
                subjectStatsSection

                // 성취 배지
                achievementsSection

                // 최근 세션 목록
                recentSessionsSection
            }
            .padding()
        }
        .navigationTitle("📊 나의 학습 기록")
        .onAppear { viewModel.loadProgress() }
        .overlay { if viewModel.isLoading { ProgressView() } }
    }

    // MARK: - 스트릭 카드
    private var streakCard: some View {
        HStack(spacing: 24) {
            VStack {
                Text("🔥 \(viewModel.currentStreak)일")
                    .font(.title).fontWeight(.bold).foregroundColor(.orange)
                Text("현재 스트릭").font(.caption).foregroundColor(.secondary)
            }
            Divider().frame(height: 50)
            VStack {
                Text("⭐ \(viewModel.longestStreak)일")
                    .font(.title).fontWeight(.bold).foregroundColor(.yellow)
                Text("최장 스트릭").font(.caption).foregroundColor(.secondary)
            }
            Divider().frame(height: 50)
            VStack {
                Text("⏱ \(viewModel.totalStudyMinutes)분")
                    .font(.title).fontWeight(.bold).foregroundColor(.blue)
                Text("총 학습 시간").font(.caption).foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.06), radius: 4)
    }

    // MARK: - 전체 정답률
    private var accuracyCard: some View {
        VStack(spacing: 8) {
            Text("전체 정답률")
                .font(.headline)
            Text("\(Int(viewModel.overallAccuracy * 100))%")
                .font(.system(size: 48, weight: .bold))
                .foregroundColor(.orange)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.orange.opacity(0.08))
        .cornerRadius(16)
    }

    // MARK: - 과목별 통계
    private var subjectStatsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("과목별 정답률").font(.headline)
            ForEach(Subject.allCases, id: \.self) { subject in
                if let stat = viewModel.subjectStats[subject] {
                    SubjectStatRow(subject: subject, stat: stat)
                }
            }
        }
    }

    // MARK: - 성취 배지
    private var achievementsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("🏆 성취 배지").font(.headline)
            if viewModel.achievements.isEmpty {
                Text("아직 배지가 없어요. 열심히 공부하면 쿠키가 배지를 줄 거야! 🐶")
                    .font(.body).foregroundColor(.secondary)
            } else {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 12) {
                    ForEach(viewModel.achievements) { badge in
                        BadgeView(achievement: badge)
                    }
                }
            }
        }
    }

    // MARK: - 최근 세션
    private var recentSessionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("최근 학습").font(.headline)
                Spacer()
                // 과목 필터
                Menu("필터") {
                    Button("전체") { viewModel.selectedSubjectFilter = nil }
                    ForEach(Subject.allCases, id: \.self) { s in
                        Button(s.rawValue) { viewModel.selectedSubjectFilter = s }
                    }
                }
            }
            ForEach(viewModel.filteredSessions) { session in
                SessionRowView(session: session)
            }
        }
    }
}

struct SubjectStatRow: View {
    let subject: Subject
    let stat: SubjectStat
    var body: some View {
        HStack {
            Text(subject.rawValue).font(.body)
            Spacer()
            ProgressView(value: stat.averageAccuracy)
                .tint(.orange).frame(width: 120)
            Text("\(Int(stat.averageAccuracy * 100))%")
                .font(.caption).foregroundColor(.secondary).frame(width: 36)
        }
    }
}

struct BadgeView: View {
    let achievement: Achievement
    var body: some View {
        VStack(spacing: 4) {
            Text("🏆").font(.system(size: 36))
            Text(achievement.title).font(.caption2).multilineTextAlignment(.center)
        }
        .padding(8)
        .background(Color.yellow.opacity(0.15))
        .cornerRadius(12)
    }
}

struct SessionRowView: View {
    let session: LearningSession
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(session.subject.rawValue).font(.headline)
                Text(session.topic).font(.caption).foregroundColor(.secondary)
            }
            Spacer()
            Text("\(Int(session.accuracyRate * 100))%")
                .font(.title3).fontWeight(.bold)
                .foregroundColor(session.accuracyRate >= 0.8 ? .green : .orange)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.04), radius: 2)
    }
}
```

### 9.6 단위 테스트

경로: `Tests/UnitTests/Progress/ProgressViewModelTests.swift`

```swift
@MainActor
final class ProgressViewModelTests: XCTestCase {
    func test_overallAccuracy_calculatedCorrectly() async {
        let mockRepo = MockSessionRepository()
        mockRepo.sessionsToReturn = [
            LearningSession.mock(accuracyRate: 0.8),
            LearningSession.mock(accuracyRate: 0.6)
        ]
        let useCase = FetchAchievementsUseCase(sessionRepo: mockRepo)
        let sut = ProgressViewModel(profile: .mock(), useCase: useCase)
        sut.recentSessions = mockRepo.sessionsToReturn
        XCTAssertEqual(sut.overallAccuracy, 0.7, accuracy: 0.001)
    }
}
```

---

## 완료 기준 확인

| 항목 | 확인 방법 |
|------|-----------|
| 스트릭 | 이틀 연속 학습 후 스트릭 2 표시 확인 |
| 배지 | 특정 과목 정답률 80% 달성 후 배지 자동 표시 |
| 과목 필터 | 필터 선택 시 해당 과목 세션만 표시 |
| 단위 테스트 | `ProgressViewModelTests` 통과 |

---

## 다음 단계

Task 9 완료 후 **Task 11 (UI 완성도)** 에서 차트와 애니메이션을 추가한다.
