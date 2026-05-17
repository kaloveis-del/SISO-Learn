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
