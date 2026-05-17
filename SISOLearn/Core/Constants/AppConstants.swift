import Foundation

// MARK: - Gemini API 한도 상수
enum GeminiAPILimits {
    static let requestsPerMinute = 15
    static let requestsPerDay = 1500
    static let maxOutputTokens = 1024
    static let explanationMaxChars = 500
    static let answerMaxChars = 1000
    static let minQuizCount = 3
    static let maxQuizCount = 10
    static let maxHintLevel = 3
}

// MARK: - 앱 전역 상수
enum AppConstants {
    static let maxProfileCount = 5
    static let achievementAccuracyThreshold = 0.8  // 80%
    static let bundleIdentifier = "com.sisolearn.app"
}

// MARK: - Keychain 키
enum KeychainKeys {
    static let service = "com.sisolearn.app"
    static let geminiAPIKey = "gemini_api_key"
}
