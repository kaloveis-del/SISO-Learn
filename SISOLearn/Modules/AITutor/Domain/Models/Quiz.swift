import Foundation

struct Quiz: Codable, Identifiable {
    let id: UUID
    let question: String
    let expectedKeywords: [String]
    let subject: Subject
    let difficulty: Difficulty
    let gradeLevel: GradeLevel
}

struct AnswerFeedback: Codable {
    let isCorrect: Bool
    let score: Int
    let explanation: String
    let correctAnswer: String
}
