import SwiftUI
import Observation

@MainActor
@Observable
final class LearningSessionViewModel {

    var currentPhase: LearningPhase = .greeting
    var explanation: String = ""
    var quizzes: [Quiz] = []
    var currentQuizIndex: Int = 0
    var userAnswer: String = ""
    var currentFeedback: AnswerFeedback?
    var hints: [String] = []
    var hintCount: Int = 0
    var isLoading: Bool = false
    var errorMessage: String?
    var sessionResults: [QuizResult] = []

    var currentQuiz: Quiz? { quizzes[safe: currentQuizIndex] }
    var progress: Double {
        guard !quizzes.isEmpty else { return 0 }
        return Double(currentQuizIndex) / Double(quizzes.count)
    }
    var accuracyRate: Double {
        guard !sessionResults.isEmpty else { return 0 }
        return Double(sessionResults.filter { $0.isCorrect }.count) / Double(sessionResults.count)
    }
    var canRequestHint: Bool { hintCount < GeminiAPILimits.maxHintLevel }
    var isAnswerEmpty: Bool { userAnswer.trimmingCharacters(in: .whitespaces).isEmpty }
    var isAnswerOverLimit: Bool { userAnswer.count > GeminiAPILimits.answerMaxChars }

    private let startSessionUseCase: StartLearningSessionUseCase
    private let submitAnswerUseCase: SubmitAnswerUseCase
    private let requestHintUseCase: RequestHintUseCase
    private let saveProgressUseCase: SaveProgressUseCase
    let cookieVM: CookieViewModel

    private var sessionId: UUID?
    private let profile: Profile
    private let subject: Subject
    private let difficulty: Difficulty
    private let topic: String
    private var sessionStartTime = Date()

    init(profile: Profile, subject: Subject, difficulty: Difficulty, topic: String,
         startSessionUseCase: StartLearningSessionUseCase,
         submitAnswerUseCase: SubmitAnswerUseCase,
         requestHintUseCase: RequestHintUseCase,
         saveProgressUseCase: SaveProgressUseCase,
         cookieVM: CookieViewModel) {
        self.profile = profile
        self.subject = subject
        self.difficulty = difficulty
        self.topic = topic
        self.startSessionUseCase = startSessionUseCase
        self.submitAnswerUseCase = submitAnswerUseCase
        self.requestHintUseCase = requestHintUseCase
        self.saveProgressUseCase = saveProgressUseCase
        self.cookieVM = cookieVM
    }

    func startSession(quizCount: Int = 5) {
        isLoading = true
        sessionStartTime = Date()
        cookieVM.updateForPhase(.greeting, userName: profile.name)
        Task {
            do {
                let result = try await startSessionUseCase.execute(
                    profile: profile, subject: subject,
                    difficulty: difficulty, topic: topic, quizCount: quizCount)
                sessionId = result.sessionId
                explanation = result.explanation
                quizzes = result.quizzes
                currentPhase = .explanation
                cookieVM.speakAIMessage(result.explanation, phase: .explanation)
            } catch { handleError(error) }
            isLoading = false
        }
    }

    func proceedToQuiz() {
        guard !quizzes.isEmpty else { return }
        currentPhase = .quiz
        cookieVM.updateForPhase(.quiz)
    }

    func requestHint() {
        guard canRequestHint, let quiz = currentQuiz else { return }
        cookieVM.updateForPhase(.hintRequested(hintCount + 1))
        isLoading = true
        Task {
            do {
                let hint = try await requestHintUseCase.execute(
                    quiz: quiz, hintLevel: hintCount + 1, gradeLevel: profile.gradeLevel)
                hints.append(hint)
                hintCount += 1
                currentPhase = .hintRequested(hintCount)
                cookieVM.speakAIMessage(hint, phase: .hintRequested(hintCount))
            } catch { handleError(error) }
            isLoading = false
        }
    }

    func submitAnswer() {
        guard !isAnswerEmpty, !isAnswerOverLimit, let quiz = currentQuiz else { return }
        isLoading = true
        Task {
            do {
                let feedback = try await submitAnswerUseCase.execute(
                    quiz: quiz, userAnswer: userAnswer,
                    gradeLevel: profile.gradeLevel, hintUsedCount: hintCount)
                currentFeedback = feedback
                sessionResults.append(QuizResult(
                    id: UUID(), sessionId: sessionId ?? UUID(),
                    quizQuestion: quiz.question, userAnswer: userAnswer,
                    isCorrect: feedback.isCorrect, score: feedback.score,
                    hintUsedCount: hintCount, feedbackText: feedback.explanation,
                    answeredAt: Date(), timeSpentSeconds: 0))
                currentPhase = .feedback
                cookieVM.updateForPhase(.feedback, isCorrect: feedback.isCorrect, userName: profile.name)
            } catch { handleError(error) }
            isLoading = false
        }
    }

    func proceedToNextQuiz() {
        userAnswer = ""; hints = []; hintCount = 0; currentFeedback = nil
        if currentQuizIndex + 1 < quizzes.count {
            currentQuizIndex += 1
            currentPhase = .quiz
            cookieVM.updateForPhase(.quiz)
        } else { completeSession() }
    }

    private func completeSession() {
        currentPhase = .sessionComplete
        cookieVM.updateForPhase(.sessionComplete, userName: profile.name)
        Task {
            guard let sid = sessionId else { return }
            let duration = Int(Date().timeIntervalSince(sessionStartTime))
            try? await saveProgressUseCase.execute(
                sessionId: sid, profileId: profile.id,
                subject: subject, difficulty: difficulty, topic: topic,
                results: sessionResults, durationSeconds: duration)
        }
    }

    private func handleError(_ error: Error) {
        if let aiError = error as? AITutorError {
            cookieVM.speakError(aiError)
            errorMessage = aiError.errorDescription
        } else {
            errorMessage = "오류가 생겼어요. 다시 시도해봐! 🥺"
        }
    }
}
