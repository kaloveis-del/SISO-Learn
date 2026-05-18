import XCTest
@testable import SISOLearn

final class ProfileLimitPropertyTests: XCTestCase {

    // CP-5: 프로필 수는 항상 5개 이하여야 한다
    func test_profileCountNeverExceedsFive() async throws {
        let repo = MockProfileRepository()
        let useCase = ManageProfileUseCase(repository: repo)

        // 7개 생성 시도
        for i in 1...7 {
            try? await useCase.create(name: "테스트\(i)", gradeLevel: .grade5Elementary, avatarIndex: 0)
        }

        let profiles = try await useCase.fetchAll()
        XCTAssertLessThanOrEqual(profiles.count, 5, "프로필은 최대 5개를 초과할 수 없습니다")
    }

    func test_profileCountAllowedUpToFive() async throws {
        let repo = MockProfileRepository()
        let useCase = ManageProfileUseCase(repository: repo)

        for i in 1...5 {
            try await useCase.create(name: "테스트\(i)", gradeLevel: .grade5Elementary, avatarIndex: 0)
        }

        let profiles = try await useCase.fetchAll()
        XCTAssertEqual(profiles.count, 5)
    }

    func test_sixthProfileThrowsError() async throws {
        let repo = MockProfileRepository()
        let useCase = ManageProfileUseCase(repository: repo)

        for i in 1...5 {
            try await useCase.create(name: "테스트\(i)", gradeLevel: .grade5Elementary, avatarIndex: 0)
        }

        do {
            try await useCase.create(name: "여섯번째", gradeLevel: .grade5Elementary, avatarIndex: 0)
            XCTFail("6번째 프로필 생성은 에러를 발생시켜야 합니다")
        } catch ProfileError.maxProfilesReached {
            // 예상된 에러
        }
    }
}
