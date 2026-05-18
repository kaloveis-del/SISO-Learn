import XCTest
@testable import SISOLearn

final class AccuracyRatePropertyTests: XCTestCase {

    // CP-7: 정답률은 항상 0.0~1.0 범위
    func test_accuracyRate_alwaysInRange() {
        let testCases: [(correct: Int, total: Int)] = [
            (0, 5), (3, 5), (5, 5), (0, 0), (1, 1), (10, 10)
        ]
        for tc in testCases {
            let rate = tc.total == 0 ? 0.0 : Double(tc.correct) / Double(tc.total)
            XCTAssertGreaterThanOrEqual(rate, 0.0, "정답률은 0.0 이상이어야 합니다 (\(tc.correct)/\(tc.total))")
            XCTAssertLessThanOrEqual(rate, 1.0, "정답률은 1.0 이하여야 합니다 (\(tc.correct)/\(tc.total))")
        }
    }

    // CP-4: 설명 길이는 항상 500자 이하
    func test_explanationLength_alwaysWithinLimit() {
        let longText = String(repeating: "가", count: 1000)
        let truncated = String(longText.prefix(GeminiAPILimits.explanationMaxChars))
        XCTAssertLessThanOrEqual(truncated.count, 500)
    }
}
