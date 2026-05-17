import Foundation

protocol ProfileRepositoryProtocol {
    func fetchAll() async throws -> [Profile]
    func create(name: String, gradeLevel: GradeLevel, avatarIndex: Int) async throws -> Profile
    func delete(id: UUID) async throws
    func updateLastActive(id: UUID) async throws
}
