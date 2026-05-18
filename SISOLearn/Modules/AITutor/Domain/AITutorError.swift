import Foundation

enum AITutorError: LocalizedError {
    case networkError(String)
    case rateLimitExceeded
    case dailyLimitExceeded
    case invalidAPIKey
    case parseError(String)
    case offline

    var errorDescription: String? {
        switch self {
        case .networkError(let msg):  return "네트워크 오류: \(msg)"
        case .rateLimitExceeded:      return "잠시 후 다시 시도해요 (분당 요청 한도 초과)"
        case .dailyLimitExceeded:     return "오늘 학습 한도에 도달했어요. 내일 다시 만나요! 🐶"
        case .invalidAPIKey:          return "API 키를 확인해주세요. 설정 화면에서 다시 입력해주세요."
        case .parseError(let msg):    return "응답 처리 오류: \(msg)"
        case .offline:                return "인터넷 연결을 확인해주세요."
        }
    }

    var isRetryable: Bool {
        switch self {
        case .networkError, .rateLimitExceeded, .parseError: return true
        default: return false
        }
    }
}
