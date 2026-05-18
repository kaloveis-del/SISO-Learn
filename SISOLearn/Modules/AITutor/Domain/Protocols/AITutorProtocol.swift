import Foundation

protocol AITutorProtocol {
    func generateExplanation(topic: String, gradeLevel: GradeLevel, subject: Subject) async throws -> String
    func generateQuizzes(topic: String, gradeLevel: GradeLevel, subject: Subject, difficulty: Difficulty, count: Int) async throws -> [Quiz]
    func evaluateAnswer(quiz: Quiz, userAnswer: String, gradeLevel: GradeLevel) async throws -> AnswerFeedback
    func generateHint(quiz: Quiz, hintLevel: Int, gradeLevel: GradeLevel) async throws -> String
    func extractTopicFromVideo(videoTitle: String, subject: Subject, gradeLevel: GradeLevel) async throws -> String
}
