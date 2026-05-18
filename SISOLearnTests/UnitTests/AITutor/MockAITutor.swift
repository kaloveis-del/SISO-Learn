import Foundation
@testable import SISOLearn

final class MockAITutor: AITutorProtocol {
    var shouldThrowError: AITutorError?
    var explanationToReturn = "쿠키가 설명해줄게! 🐾"
    var quizzesToReturn: [Quiz] = []
    var feedbackToReturn = AnswerFeedback(isCorrect: true, score: 80, explanation: "와! 정답이야! ��", correctAnswer: "")
    var hintToReturn = "힌트! 이걸 생각해봐~ 🤔"

    var generateExplanationCallCount = 0
    var generateQuizzesCallCount = 0
    var evaluateAnswerCallCount = 0
    var generateHintCallCount = 0
    var lastHintLevelRequested: Int?
    var lastUserAnswerReceived: String?

    func generateExplanation(topic: String, gradeLevel: GradeLevel, subject: Subject) async throws -> String {
        generateExplanationCallCount += 1
        if let error = shouldThrowError { throw error }
        return explanationToReturn
    }

    func generateQuizzes(topic: String, gradeLevel: GradeLevel, subject: Subject, difficulty: Difficulty, count: Int) async throws -> [Quiz] {
        generateQuizzesCallCount += 1
        if let error = shouldThrowError { throw error }
        return quizzesToReturn
    }

    func evaluateAnswer(quiz: Quiz, userAnswer: String, gradeLevel: GradeLevel) async throws -> AnswerFeedback {
        evaluateAnswerCallCount += 1
        lastUserAnswerReceived = userAnswer
        if let error = shouldThrowError { throw error }
        return feedbackToReturn
    }

    func generateHint(quiz: Quiz, hintLevel: Int, gradeLevel: GradeLevel) async throws -> String {
        generateHintCallCount += 1
        lastHintLevelRequested = hintLevel
        if let error = shouldThrowError { throw error }
        return hintToReturn
    }

    func extractTopicFromVideo(videoTitle: String, subject: Subject, gradeLevel: GradeLevel) async throws -> String {
        if let error = shouldThrowError { throw error }
        return "테스트 학습 주제"
    }
}
