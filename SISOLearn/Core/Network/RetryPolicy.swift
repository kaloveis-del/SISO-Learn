import Foundation

struct RetryPolicy {
    let maxAttempts: Int = 3
    let baseDelay: TimeInterval = 1.0
    let multiplier: Double = 2.0

    func delay(for attempt: Int) -> TimeInterval {
        baseDelay * pow(multiplier, Double(attempt - 1))
    }

    func shouldRetry(error: AITutorError, attempt: Int) -> Bool {
        guard attempt < maxAttempts else { return false }
        return error.isRetryable
    }
}
