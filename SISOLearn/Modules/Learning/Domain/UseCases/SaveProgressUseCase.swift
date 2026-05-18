import Foundation

final class SaveProgressUseCase {
    private let sessionRepo: SessionRepositoryProtocol

    init(sessionRepo: SessionRepositoryProtocol) { self.sessionRepo = sessionRepo }

    func execute(sessionId: UUID, profileId: UUID, subject: Subject,
                 difficulty: Difficulty, topic: String,
                 results: [QuizResult], durationSeconds: Int,
                 youtubeVideoId: String? = nil) async throws {
        let correctCount = results.filter { $0.isCorrect }.count
        let accuracyRate = results.isEmpty ? 0.0 : Double(correctCount) / Double(results.count)
        let session = LearningSession(
            id: sessionId, profileId: profileId,
            subject: subject, difficulty: difficulty, topic: topic,
            startedAt: Date().addingTimeInterval(-Double(durationSeconds)),
            completedAt: Date(),
            totalQuizCount: results.count, correctCount: correctCount,
            accuracyRate: accuracyRate, youtubeVideoId: youtubeVideoId,
            durationSeconds: durationSeconds
        )
        try await sessionRepo.save(session: session, results: results)
        try await sessionRepo.updateStreak(profileId: profileId)
    }
}
