import Foundation
import CoreData

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
