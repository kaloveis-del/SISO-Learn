import XCTest
@testable import SISOLearn

final class AIPropertyTests: XCTestCase {

    // CP-1: Quiz 수는 항상 3~10 범위
    func test_quizCount_alwaysInRange() {
        let inputs = [-5, 0, 1, 2, 3, 5, 10, 11, 20]
        for input in inputs {
            let clamped = max(GeminiAPILimits.minQuizCount, min(GeminiAPILimits.maxQuizCount, input))
            XCTAssertGreaterThanOrEqual(clamped, 3, "Quiz 수는 3 이상이어야 합니다 (입력: \(input))")
            XCTAssertLessThanOrEqual(clamped, 10, "Quiz 수는 10 이하여야 합니다 (입력: \(input))")
        }
    }

    // CP-2: 힌트 단계는 항상 1~3 범위
    func test_hintLevel_alwaysInRange() {
        let inputs = [-2, 0, 1, 2, 3, 4, 5]
        for input in inputs {
            let clamped = max(1, min(GeminiAPILimits.maxHintLevel, input))
            XCTAssertGreaterThanOrEqual(clamped, 1, "힌트 단계는 1 이상이어야 합니다 (입력: \(input))")
            XCTAssertLessThanOrEqual(clamped, 3, "힌트 단계는 3 이하여야 합니다 (입력: \(input))")
        }
    }

    // CP-3: 답변 길이는 항상 1,000자 이하
    func test_answerLength_alwaysWithinLimit() {
        let inputs = [0, 500, 999, 1000, 1001, 2000, 5000]
        for length in inputs {
            let input = String(repeating: "가", count: length)
            let truncated = String(input.prefix(GeminiAPILimits.answerMaxChars))
            XCTAssertLessThanOrEqual(truncated.count, 1000, "답변은 1,000자 이하여야 합니다 (입력: \(length)자)")
        }
    }

    // CP-4: 설명 길이는 항상 500자 이하
    func test_explanationLength_alwaysWithinLimit() {
        let longText = String(repeating: "가", count: 1000)
        let truncated = String(longText.prefix(GeminiAPILimits.explanationMaxChars))
        XCTAssertLessThanOrEqual(truncated.count, 500)
    }
}
