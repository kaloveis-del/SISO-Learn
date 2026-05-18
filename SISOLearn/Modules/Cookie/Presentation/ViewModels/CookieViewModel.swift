import SwiftUI
import Observation

@Observable
@MainActor
final class CookieViewModel {
    var currentMessage: String = ""
    var currentEmotion: CookieEmotion = .normal
    var isTyping: Bool = false

    func speak(_ message: String, emotion: CookieEmotion, animated: Bool = true) {
        currentEmotion = emotion
        if animated {
            isTyping = true
            Task {
                try? await Task.sleep(nanoseconds: 500_000_000)
                currentMessage = message
                isTyping = false
            }
        } else {
            currentMessage = message
            isTyping = false
        }
    }

    func updateForPhase(_ phase: LearningPhase, isCorrect: Bool? = nil, userName: String = "") {
        let emotion = CookieEmotion.from(phase: phase, isCorrect: isCorrect)
        let message: String
        switch phase {
        case .greeting:
            message = CookieMessageTemplates.random(from: CookieMessageTemplates.greetings)
        case .explanation:
            message = CookieMessageTemplates.random(from: CookieMessageTemplates.subjectPrompts)
        case .quiz, .answering:
            message = CookieMessageTemplates.random(from: CookieMessageTemplates.waitingMessages)
        case .hintRequested:
            message = CookieMessageTemplates.random(from: CookieMessageTemplates.beforeHint)
        case .feedback:
            if let correct = isCorrect {
                message = correct
                    ? CookieMessageTemplates.random(from: CookieMessageTemplates.correctResponses)
                    : CookieMessageTemplates.random(from: CookieMessageTemplates.incorrectResponses)
            } else { message = "" }
        case .sessionComplete:
            message = CookieMessageTemplates.random(from: CookieMessageTemplates.sessionComplete)
        }
        speak(message, emotion: emotion)
    }

    func speakAIMessage(_ message: String, phase: LearningPhase) {
        speak(message, emotion: CookieEmotion.from(phase: phase))
    }

    func speakError(_ error: AITutorError) {
        let message: String
        switch error {
        case .offline:
            message = CookieMessageTemplates.random(from: CookieMessageTemplates.offlineMessages)
        case .rateLimitExceeded:
            message = CookieMessageTemplates.random(from: CookieMessageTemplates.rateLimitMessages)
        default:
            message = error.errorDescription ?? "오류가 생겼어요. 다시 시도해봐! 🥺"
        }
        speak(message, emotion: .comforting)
    }
}
