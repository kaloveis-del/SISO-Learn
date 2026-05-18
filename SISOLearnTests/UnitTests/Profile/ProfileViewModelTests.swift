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

    func test_canAddProfile_falseWhenFiveProfiles() {
        sut.profiles = (0..<5).map { i in
            Profile(id: UUID(), name: "테스트\(i)", gradeLevel: .grade5Elementary,
                    avatarIndex: 0, createdAt: Date(), lastActiveAt: Date(),
                    totalStudyMinutes: 0, currentStreak: 0, longestStreak: 0)
        }
        XCTAssertFalse(sut.canAddProfile)
    }

    func test_isNewProfileValid_falseWhenBlank() {
        sut.newProfileName = "   "
        XCTAssertFalse(sut.isNewProfileValid)
    }

    func test_isNewProfileValid_trueWhenHasName() {
        sut.newProfileName = "쿠키"
        XCTAssertTrue(sut.isNewProfileValid)
    }

    func test_deleteProfile_removesFromList() async {
        let profile = Profile(id: UUID(), name: "삭제테스트", gradeLevel: .grade5Elementary,
                              avatarIndex: 0, createdAt: Date(), lastActiveAt: Date(),
                              totalStudyMinutes: 0, currentStreak: 0, longestStreak: 0)
        sut.profiles = [profile]
        mockRepo.profilesToReturn = [profile]
        sut.deleteProfile(profile)
        try? await Task.sleep(nanoseconds: 100_000_000)
        XCTAssertTrue(sut.profiles.isEmpty)
    }
}

// MARK: - Mock
final class MockProfileRepository: ProfileRepositoryProtocol {
    var profilesToReturn: [Profile] = []

    func fetchAll() async throws -> [Profile] { profilesToReturn }

    func create(name: String, gradeLevel: GradeLevel, avatarIndex: Int) async throws -> Profile {
        let p = Profile(id: UUID(), name: name, gradeLevel: gradeLevel,
                        avatarIndex: avatarIndex, createdAt: Date(), lastActiveAt: Date(),
                        totalStudyMinutes: 0, currentStreak: 0, longestStreak: 0)
        profilesToReturn.append(p)
        return p
    }

    func delete(id: UUID) async throws {
        profilesToReturn.removeAll { $0.id == id }
    }

    func updateLastActive(id: UUID) async throws {}
}
