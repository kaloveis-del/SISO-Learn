import Foundation

final class GeminiAITutor: AITutorProtocol {

    private let apiKey: String
    private let session: URLSession
    private let retryPolicy: RetryPolicy
    private let baseURL = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash-lite:generateContent"
    private var dailyRequestCount = 0
    private var lastResetDate = Date()

    init(apiKey: String, session: URLSession = .shared, retryPolicy: RetryPolicy = RetryPolicy()) {
        self.apiKey = apiKey
        self.session = session
        self.retryPolicy = retryPolicy
    }

    func generateExplanation(topic: String, gradeLevel: GradeLevel, subject: Subject) async throws -> String {
        let prompt = CookiePersonaWrapper.explanationPrompt(topic: topic, gradeLevel: gradeLevel, subject: subject)
        let response = try await sendWithRetry(prompt: prompt)
        return String(extractText(from: response).prefix(GeminiAPILimits.explanationMaxChars))
    }

    func generateQuizzes(topic: String, gradeLevel: GradeLevel, subject: Subject, difficulty: Difficulty, count: Int) async throws -> [Quiz] {
        let clamped = max(GeminiAPILimits.minQuizCount, min(GeminiAPILimits.maxQuizCount, count))
        let prompt = CookiePersonaWrapper.quizPrompt(topic: topic, gradeLevel: gradeLevel, subject: subject, difficulty: difficulty, count: clamped)
        let response = try await sendWithRetry(prompt: prompt)
        return try parseQuizzes(from: response)
    }

    func evaluateAnswer(quiz: Quiz, userAnswer: String, gradeLevel: GradeLevel) async throws -> AnswerFeedback {
        let truncated = String(userAnswer.prefix(GeminiAPILimits.answerMaxChars))
        let prompt = CookiePersonaWrapper.feedbackPrompt(quiz: quiz, userAnswer: truncated, gradeLevel: gradeLevel)
        let response = try await sendWithRetry(prompt: prompt)
        return try parseFeedback(from: response)
    }

    func generateHint(quiz: Quiz, hintLevel: Int, gradeLevel: GradeLevel) async throws -> String {
        let clamped = max(1, min(GeminiAPILimits.maxHintLevel, hintLevel))
        let prompt = CookiePersonaWrapper.hintPrompt(quiz: quiz, hintLevel: clamped, gradeLevel: gradeLevel)
        let response = try await sendWithRetry(prompt: prompt)
        return extractText(from: response)
    }

    func extractTopicFromVideo(videoTitle: String, subject: Subject, gradeLevel: GradeLevel) async throws -> String {
        let prompt = "YouTube 영상 제목: \(videoTitle)\n과목: \(subject.rawValue)\n학습자 수준: \(gradeLevel.vocabularyLevel)\n영상과 관련된 학습 주제를 한 문장으로 작성해주세요."
        let response = try await sendWithRetry(prompt: prompt)
        return extractText(from: response)
    }

    private func sendWithRetry(prompt: String, attempt: Int = 1) async throws -> GeminiResponse {
        do {
            return try await sendRequest(prompt: prompt)
        } catch let error as AITutorError {
            if retryPolicy.shouldRetry(error: error, attempt: attempt) {
                let delay = retryPolicy.delay(for: attempt)
                try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                return try await sendWithRetry(prompt: prompt, attempt: attempt + 1)
            }
            throw error
        }
    }

    private func sendRequest(prompt: String) async throws -> GeminiResponse {
        try checkRateLimit()
        guard let url = URL(string: "\(baseURL)?key=\(apiKey)") else {
            throw AITutorError.networkError("잘못된 URL")
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30
        request.httpBody = try JSONEncoder().encode(GeminiRequest(prompt: prompt))

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AITutorError.networkError("응답 없음")
        }
        switch httpResponse.statusCode {
        case 200:
            dailyRequestCount += 1
            return try JSONDecoder().decode(GeminiResponse.self, from: data)
        case 429:
            print("⚠️ Gemini API 429 Rate Limit - 잠시 후 재시도")
            throw AITutorError.rateLimitExceeded
        case 401, 403:
            print("⚠️ Gemini API 401/403 - API Key 오류")
            throw AITutorError.invalidAPIKey
        case 503:
            throw AITutorError.networkError("서버가 바빠요. 잠시 후 다시 시도해주세요")
        default:
            print("⚠️ Gemini API HTTP \(httpResponse.statusCode)")
            throw AITutorError.networkError("HTTP \(httpResponse.statusCode)")
        }
    }

    private func checkRateLimit() throws {
        let now = Date()
        if !Calendar.current.isDate(now, inSameDayAs: lastResetDate) {
            dailyRequestCount = 0
            lastResetDate = now
        }
        if dailyRequestCount >= GeminiAPILimits.requestsPerDay {
            throw AITutorError.dailyLimitExceeded
        }
    }

    private func extractText(from response: GeminiResponse) -> String {
        response.candidates.first?.content.parts.first?.text ?? ""
    }

    private func parseQuizzes(from response: GeminiResponse) throws -> [Quiz] {
        let text = extractText(from: response)
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard let data = text.data(using: .utf8) else {
            throw AITutorError.parseError("Quiz JSON 변환 실패")
        }
        return try JSONDecoder().decode([Quiz].self, from: data)
    }

    private func parseFeedback(from response: GeminiResponse) throws -> AnswerFeedback {
        let text = extractText(from: response)
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard let data = text.data(using: .utf8) else {
            throw AITutorError.parseError("Feedback JSON 변환 실패")
        }
        return try JSONDecoder().decode(AnswerFeedback.self, from: data)
    }
}
