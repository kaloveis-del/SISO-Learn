import Foundation

struct Profile: Identifiable, Equatable {
    let id: UUID
    var name: String
    var gradeLevel: GradeLevel
    var avatarIndex: Int
    var createdAt: Date
    var lastActiveAt: Date
    var totalStudyMinutes: Int
    var currentStreak: Int
    var longestStreak: Int
}

enum GradeLevel: String, Codable, CaseIterable {
    case grade5Elementary = "초등학교 5학년"
    case grade2Middle = "중학교 2학년"

    var vocabularyLevel: String {
        switch self {
        case .grade5Elementary:
            return "초등학교 5학년 수준. 한자어 최소화, 짧고 쉬운 문장 사용."
        case .grade2Middle:
            return "중학교 2학년 수준. 교과서 용어 포함, 개념 설명 포함."
        }
    }
}
