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
