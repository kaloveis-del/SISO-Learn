import XCTest
@testable import SISOLearn

@MainActor
final class ProgressViewModelTests: XCTestCase {

    func test_overallAccuracy_calculatedCorrectly() {
        let profile = Profile(id: UUID(), name: "테스트", gradeLevel: .grade5Elementary,
                              avatarIndex: 0, createdAt: Date(), lastActiveAt: Date(),
                              totalStudyMinutes: 60, currentStreak: 3, longestStreak: 5)
        let mockRepo = MockSessionRepository()
        let useCase = FetchAchievementsUseCase(sessionRepo: mockRepo)
        let sut = ProgressViewModel(profile: profile, useCase: useCase)

        sut.recentSessions = [
            LearningSession(id: UUID(), profileId: profile.id, subject: .math, difficulty: .normal,
                            topic: "분수", startedAt: Date(), completedAt: Date(),
                            totalQuizCount: 5, correctCount: 4, accuracyRate: 0.8,
                            youtubeVideoId: nil, durationSeconds: 300),
            LearningSession(id: UUID(), profileId: profile.id, subject: .english, difficulty: .easy,
                            topic: "단어", startedAt: Date(), completedAt: Date(),
                            totalQuizCount: 5, correctCount: 3, accuracyRate: 0.6,
                            youtubeVideoId: nil, durationSeconds: 200)
        ]
        XCTAssertEqual(sut.overallAccuracy, 0.7, accuracy: 0.001)
    }

    func test_filteredSessions_filtersBySubject() {
        let profile = Profile(id: UUID(), name: "테스트", gradeLevel: .grade5Elementary,
                              avatarIndex: 0, createdAt: Date(), lastActiveAt: Date(),
                              totalStudyMinutes: 0, currentStreak: 0, longestStreak: 0)
        let mockRepo = MockSessionRepository()
        let useCase = FetchAchievementsUseCase(sessionRepo: mockRepo)
        let sut = ProgressViewModel(profile: profile, useCase: useCase)

        sut.recentSessions = [
            LearningSession(id: UUID(), profileId: profile.id, subject: .math, difficulty: .normal,
                            topic: "분수", startedAt: Date(), completedAt: Date(),
                            totalQuizCount: 5, correctCount: 4, accuracyRate: 0.8,
                            youtubeVideoId: nil, durationSeconds: 300),
            LearningSession(id: UUID(), profileId: profile.id, subject: .english, difficulty: .easy,
                            topic: "단어", startedAt: Date(), completedAt: Date(),
                            totalQuizCount: 5, correctCount: 3, accuracyRate: 0.6,
                            youtubeVideoId: nil, durationSeconds: 200)
        ]

        sut.selectedSubjectFilter = .math
        XCTAssertEqual(sut.filteredSessions.count, 1)
        XCTAssertEqual(sut.filteredSessions.first?.subject, .math)
    }
}
