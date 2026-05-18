import Foundation

enum LearningPhase: Equatable {
    case greeting
    case explanation
    case quiz
    case answering
    case hintRequested(Int)
    case feedback
    case sessionComplete

    static func == (lhs: LearningPhase, rhs: LearningPhase) -> Bool {
        switch (lhs, rhs) {
        case (.greeting, .greeting), (.explanation, .explanation),
             (.quiz, .quiz), (.answering, .answering),
             (.feedback, .feedback), (.sessionComplete, .sessionComplete): return true
        case (.hintRequested(let a), .hintRequested(let b)): return a == b
        default: return false
        }
    }
}

enum CookieEmotion: String, CaseIterable {
    case normal     = "normal"
    case excited    = "excited"
    case praising   = "praising"
    case thinking   = "thinking"
    case comforting = "comforting"

    var emoji: String {
        switch self {
        case .normal:     return "😊"
        case .excited:    return "🐾"
        case .praising:   return "🎉"
        case .thinking:   return "🤔"
        case .comforting: return "🥺"
        }
    }

    static func from(phase: LearningPhase, isCorrect: Bool? = nil) -> CookieEmotion {
        switch phase {
        case .greeting, .explanation: return .excited
        case .quiz, .hintRequested:   return .thinking
        case .answering:              return .normal
        case .feedback:
            guard let correct = isCorrect else { return .normal }
            return correct ? .praising : .comforting
        case .sessionComplete:        return .praising
        }
    }
}
