import Foundation

protocol SessionRepositoryProtocol {
    func save(session: LearningSession, results: [QuizResult]) async throws
    func fetchRecent(profileId: UUID, limit: Int) async throws -> [LearningSession]
    func fetchSubjectStats(profileId: UUID) async throws -> [Subject: SubjectStat]
    func updateStreak(profileId: UUID) async throws
}

struct SubjectStat {
    let subject: Subject
    let totalSessions: Int
    let averageAccuracy: Double
    let totalQuizzes: Int
    let correctQuizzes: Int
}
