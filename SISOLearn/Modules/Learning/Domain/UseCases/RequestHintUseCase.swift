import Foundation

final class RequestHintUseCase {
    private let aiTutor: AITutorProtocol

    init(aiTutor: AITutorProtocol) { self.aiTutor = aiTutor }

    func execute(quiz: Quiz, hintLevel: Int, gradeLevel: GradeLevel) async throws -> String {
        let clamped = max(1, min(GeminiAPILimits.maxHintLevel, hintLevel))
        return try await aiTutor.generateHint(
            quiz: quiz, hintLevel: clamped, gradeLevel: gradeLevel)
    }
}
