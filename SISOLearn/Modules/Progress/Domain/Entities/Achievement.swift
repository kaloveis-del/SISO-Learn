import Foundation

struct Achievement: Identifiable {
    let id: UUID
    let profileId: UUID
    var badgeType: AchievementType
    var subject: Subject?
    var earnedAt: Date
    var title: String
    var descriptionText: String
}

enum AchievementType: String, CaseIterable {
    case mathMaster    = "math_master"
    case englishMaster = "english_master"
    case scienceMaster = "science_master"
    case koreanMaster  = "korean_master"
    case streakWeek    = "streak_week"
    case firstSession  = "first_session"
}
