import XCTest
@testable import SISOLearn

@MainActor
final class ErrorHandlingTests: XCTestCase {

    func test_offlineError_cookieSpeaksComforting() {
        let cookieVM = CookieViewModel()
        cookieVM.speakError(.offline)
        XCTAssertEqual(cookieVM.currentEmotion, .comforting)
    }

    func test_rateLimitError_cookieSpeaksComforting() {
        let cookieVM = CookieViewModel()
        cookieVM.speakError(.rateLimitExceeded)
        XCTAssertEqual(cookieVM.currentEmotion, .comforting)
    }

    func test_invalidAPIKeyError_isNotRetryable() {
        XCTAssertFalse(AITutorError.invalidAPIKey.isRetryable)
    }

    func test_networkError_isRetryable() {
        XCTAssertTrue(AITutorError.networkError("test").isRetryable)
    }

    func test_dailyLimitError_isNotRetryable() {
        XCTAssertFalse(AITutorError.dailyLimitExceeded.isRetryable)
    }

    func test_parseError_isRetryable() {
        XCTAssertTrue(AITutorError.parseError("test").isRetryable)
    }

    func test_offlineError_isNotRetryable() {
        XCTAssertFalse(AITutorError.offline.isRetryable)
    }
}
