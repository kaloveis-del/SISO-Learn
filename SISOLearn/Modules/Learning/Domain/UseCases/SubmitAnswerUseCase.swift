import Foundation

final class SubmitAnswerUseCase {
    private let aiTutor: AITutorProtocol

    init(aiTutor: AITutorProtocol) { self.aiTutor = aiTutor }

    func execute(quiz: Quiz, userAnswer: String,
                 gradeLevel: GradeLevel, hintUsedCount: Int) async throws -> AnswerFeedback {
        let truncated = String(userAnswer.prefix(GeminiAPILimits.answerMaxChars))
        return try await aiTutor.evaluateAnswer(
            quiz: quiz, userAnswer: truncated, gradeLevel: gradeLevel)
    }
}
