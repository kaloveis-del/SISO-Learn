import Foundation

struct QuizResult: Identifiable {
    let id: UUID
    let sessionId: UUID
    var quizQuestion: String
    var userAnswer: String
    var isCorrect: Bool
    var score: Int
    var hintUsedCount: Int
    var feedbackText: String
    var answeredAt: Date
    var timeSpentSeconds: Int
}
