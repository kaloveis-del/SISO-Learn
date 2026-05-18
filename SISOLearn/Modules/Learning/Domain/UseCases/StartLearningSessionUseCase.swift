import Foundation

struct SessionStartResult {
    let sessionId: UUID
    let explanation: String
    let quizzes: [Quiz]
}

final class StartLearningSessionUseCase {
    private let aiTutor: AITutorProtocol

    init(aiTutor: AITutorProtocol) {
        self.aiTutor = aiTutor
    }

    func execute(profile: Profile, subject: Subject, difficulty: Difficulty,
                 topic: String, quizCount: Int = 5) async throws -> SessionStartResult {
        async let explanation = aiTutor.generateExplanation(
            topic: topic, gradeLevel: profile.gradeLevel, subject: subject)
        async let quizzes = aiTutor.generateQuizzes(
            topic: topic, gradeLevel: profile.gradeLevel,
            subject: subject, difficulty: difficulty, count: quizCount)
        return SessionStartResult(
            sessionId: UUID(),
            explanation: try await explanation,
            quizzes: try await quizzes
        )
    }
}
