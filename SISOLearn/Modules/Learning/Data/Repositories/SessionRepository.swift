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
            profile.currentStreak += 1
        } else if !Calendar.current.isDateInToday(lastActive) {
            profile.currentStreak = 1
        }
        if profile.currentStreak > profile.longestStreak {
            profile.longestStreak = profile.currentStreak
        }
        profile.lastActiveAt = Date()
        try stack.save()
    }
}

// MARK: - CoreData Entity → Domain 변환
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
