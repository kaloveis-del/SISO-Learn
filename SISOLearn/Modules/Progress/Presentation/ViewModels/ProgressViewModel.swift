import SwiftUI
import Observation

@MainActor
@Observable
final class ProgressViewModel {

    var recentSessions: [LearningSession] = []
    var achievements: [Achievement] = []
    var subjectStats: [Subject: SubjectStat] = [:]
    var currentStreak: Int = 0
    var longestStreak: Int = 0
    var totalStudyMinutes: Int = 0
    var isLoading = false
    var selectedSubjectFilter: Subject? = nil

    var filteredSessions: [LearningSession] {
        guard let filter = selectedSubjectFilter else { return recentSessions }
        return recentSessions.filter { $0.subject == filter }
    }

    var overallAccuracy: Double {
        guard !recentSessions.isEmpty else { return 0 }
        return recentSessions.map(\.accuracyRate).reduce(0, +) / Double(recentSessions.count)
    }

    private let useCase: FetchAchievementsUseCase
    private let profile: Profile

    init(profile: Profile, useCase: FetchAchievementsUseCase) {
        self.profile = profile
        self.useCase = useCase
    }

    func loadProgress() {
        isLoading = true
        Task {
            async let sessions = useCase.fetchRecentSessions(profileId: profile.id)
            async let badges = useCase.fetchAchievements(profileId: profile.id)
            async let stats = useCase.fetchSubjectStats(profileId: profile.id)

            recentSessions = (try? await sessions) ?? []
            achievements = (try? await badges) ?? []
            subjectStats = (try? await stats) ?? [:]
            currentStreak = profile.currentStreak
            longestStreak = profile.longestStreak
            totalStudyMinutes = profile.totalStudyMinutes
            isLoading = false
        }
    }
}
