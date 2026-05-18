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
        let existing = try await repository.fetchAll()
        guard existing.count < AppConstants.maxProfileCount else {
            throw ProfileError.maxProfilesReached
        }
        guard !name.isBlank else {
            throw ProfileError.invalidName
        }
        return try await repository.create(
            name: name.trimmingCharacters(in: .whitespaces),
            gradeLevel: gradeLevel,
            avatarIndex: avatarIndex
        )
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
        case .invalidName:        return "이름을 입력해주세요"
        }
    }
}
