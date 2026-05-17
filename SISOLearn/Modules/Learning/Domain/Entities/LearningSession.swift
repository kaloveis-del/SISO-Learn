import Foundation

struct LearningSession: Identifiable {
    let id: UUID
    let profileId: UUID
    var subject: Subject
    var difficulty: Difficulty
    var topic: String
    var startedAt: Date
    var completedAt: Date?
    var totalQuizCount: Int
    var correctCount: Int
    var accuracyRate: Double
    var youtubeVideoId: String?
    var durationSeconds: Int
}

enum Subject: String, Codable, CaseIterable {
    case math = "수학"
    case english = "영어"
    case science = "과학"
    case korean = "국어"
}

enum Difficulty: String, Codable, CaseIterable {
    case easy = "쉬움"
    case normal = "보통"
    case hard = "어려움"
}
