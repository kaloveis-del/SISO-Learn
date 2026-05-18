import XCTest
@testable import SISOLearn

@MainActor
final class CookieViewModelTests: XCTestCase {
    var sut: CookieViewModel!

    override func setUp() {
        super.setUp()
        sut = CookieViewModel()
    }

    func test_speak_updatesMessageAndEmotion() {
        sut.speak("테스트 메시지", emotion: .praising, animated: false)
        XCTAssertEqual(sut.currentMessage, "테스트 메시지")
        XCTAssertEqual(sut.currentEmotion, .praising)
        XCTAssertFalse(sut.isTyping)
    }

    func test_updateForPhase_greeting_setsExcited() {
        sut.updateForPhase(.greeting)
        XCTAssertEqual(sut.currentEmotion, .excited)
    }

    func test_updateForPhase_feedback_correct_setsPraising() {
        sut.updateForPhase(.feedback, isCorrect: true)
        XCTAssertEqual(sut.currentEmotion, .praising)
    }

    func test_updateForPhase_feedback_incorrect_setsComforting() {
        sut.updateForPhase(.feedback, isCorrect: false)
        XCTAssertEqual(sut.currentEmotion, .comforting)
    }

    func test_emotionFrom_phase_mapping() {
        XCTAssertEqual(CookieEmotion.from(phase: .greeting), .excited)
        XCTAssertEqual(CookieEmotion.from(phase: .quiz), .thinking)
        XCTAssertEqual(CookieEmotion.from(phase: .feedback, isCorrect: true), .praising)
        XCTAssertEqual(CookieEmotion.from(phase: .feedback, isCorrect: false), .comforting)
        XCTAssertEqual(CookieEmotion.from(phase: .sessionComplete), .praising)
    }
}
