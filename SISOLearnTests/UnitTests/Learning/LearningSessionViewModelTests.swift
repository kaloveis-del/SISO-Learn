import XCTest
@testable import SISOLearn

@MainActor
final class LearningSessionViewModelTests: XCTestCase {

    var sut: LearningSessionViewModel!
    var mockAI: MockAITutor!

    override func setUp() {
        super.setUp()
        mockAI = MockAITutor()
        mockAI.quizzesToReturn = [
            Quiz(id: UUID(), question: "자, 문제야! 🤔", expectedKeywords: ["키워드"],
                 subject: .math, difficulty: .normal, gradeLevel: .grade5Elementary)
        ]
        let profile = Profile(id: UUID(), name: "테스트", gradeLevel: .grade5Elementary,
                              avatarIndex: 0, createdAt: Date(), lastActiveAt: Date(),
                              totalStudyMinutes: 0, currentStreak: 0, longestStreak: 0)
        sut = LearningSessionViewModel(
            profile: profile, subject: .math, difficulty: .normal, topic: "분수",
            startSessionUseCase: StartLearningSessionUseCase(aiTutor: mockAI),
            submitAnswerUseCase: SubmitAnswerUseCase(aiTutor: mockAI),
            requestHintUseCase: RequestHintUseCase(aiTutor: mockAI),
            saveProgressUseCase: SaveProgressUseCase(sessionRepo: MockSessionRepository()))
    }

    // CP-2: 힌트는 최대 3단계
    func test_requestHint_cannotExceedThree() async {
        sut.quizzes = mockAI.quizzesToReturn
        sut.currentPhase = .quiz
        for _ in 0..<3 {
            sut.requestHint()
            try? await Task.sleep(nanoseconds: 100_000_000)
        }
        XCTAssertFalse(sut.canRequestHint)
        XCTAssertEqual(sut.hintCount, 3)
        XCTAssertEqual(mockAI.generateHintCallCount, 3)
    }

    // CP-3: 1000자 초과 답변 제출 차단
    func test_submitAnswer_blockedWhenOverLimit() async {
        sut.quizzes = mockAI.quizzesToReturn
        sut.userAnswer = String(repeating: "가", count: 1001)
        XCTAssertTrue(sut.isAnswerOverLimit)
        sut.submitAnswer()
        try? await Task.sleep(nanoseconds: 100_000_000)
        XCTAssertEqual(mockAI.evaluateAnswerCallCount, 0)
    }

    // 정답률 계산
    func test_accuracyRate_calculatedCorrectly() {
        let make = { (correct: Bool) in
            QuizResult(id: UUID(), sessionId: UUID(), quizQuestion: "q", userAnswer: "a",
                       isCorrect: correct, score: correct ? 100 : 0, hintUsedCount: 0,
                       feedbackText: "", answeredAt: Date(), timeSpentSeconds: 0)
        }
        sut.sessionResults = [make(true), make(true), make(false)]
        XCTAssertEqual(sut.accuracyRate, 2.0/3.0, accuracy: 0.001)
    }

    // 빈 답변 제출 차단
    func test_submitAnswer_blockedWhenEmpty() async {
        sut.quizzes = mockAI.quizzesToReturn
        sut.userAnswer = "   "
        XCTAssertTrue(sut.isAnswerEmpty)
        sut.submitAnswer()
        try? await Task.sleep(nanoseconds: 100_000_000)
        XCTAssertEqual(mockAI.evaluateAnswerCallCount, 0)
    }
}

// MARK: - Mock
final class MockSessionRepository: SessionRepositoryProtocol {
    func save(session: LearningSession, results: [QuizResult]) async throws {}
    func fetchRecent(profileId: UUID, limit: Int) async throws -> [LearningSession] { [] }
    func fetchSubjectStats(profileId: UUID) async throws -> [Subject: SubjectStat] { [:] }
    func updateStreak(profileId: UUID) async throws {}
}
