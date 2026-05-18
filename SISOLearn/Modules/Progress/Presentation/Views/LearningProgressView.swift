import SwiftUI

struct LearningProgressView: View {
    @State private var viewModel: ProgressViewModel

    init(profile: Profile, useCase: FetchAchievementsUseCase) {
        _viewModel = State(initialValue: ProgressViewModel(profile: profile, useCase: useCase))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                streakCard
                accuracyCard
                subjectStatsSection
                achievementsSection
                recentSessionsSection
            }
            .padding()
        }
        .navigationTitle("📊 나의 학습 기록")
        .onAppear { viewModel.loadProgress() }
        .overlay { if viewModel.isLoading { ProgressView() } }
    }

    private var streakCard: some View {
        HStack(spacing: 24) {
            VStack {
                Text("🔥 \(viewModel.currentStreak)일").font(.title).fontWeight(.bold).foregroundColor(.orange)
                Text("현재 스트릭").font(.caption).foregroundColor(.secondary)
            }
            Divider().frame(height: 50)
            VStack {
                Text("⭐ \(viewModel.longestStreak)일").font(.title).fontWeight(.bold).foregroundColor(.yellow)
                Text("최장 스트릭").font(.caption).foregroundColor(.secondary)
            }
            Divider().frame(height: 50)
            VStack {
                Text("⏱ \(viewModel.totalStudyMinutes)분").font(.title).fontWeight(.bold).foregroundColor(.blue)
                Text("총 학습 시간").font(.caption).foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground)).cornerRadius(16)
        .shadow(color: .black.opacity(0.06), radius: 4)
    }

    private var accuracyCard: some View {
        VStack(spacing: 8) {
            Text("전체 정답률").font(.headline)
            Text("\(Int(viewModel.overallAccuracy * 100))%")
                .font(.system(size: 48, weight: .bold)).foregroundColor(.orange)
        }
        .frame(maxWidth: .infinity).padding()
        .background(Color.orange.opacity(0.08)).cornerRadius(16)
    }

    private var subjectStatsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("과목별 정답률").font(.headline)
            ForEach(Subject.allCases, id: \.self) { subject in
                if let stat = viewModel.subjectStats[subject] {
                    HStack {
                        Text(subject.rawValue).font(.body)
                        Spacer()
                        SwiftUI.ProgressView(value: stat.averageAccuracy).tint(.orange).frame(width: 120)
                        Text("\(Int(stat.averageAccuracy * 100))%").font(.caption).foregroundColor(.secondary).frame(width: 36)
                    }
                }
            }
        }
    }

    private var achievementsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("🏆 성취 배지").font(.headline)
            if viewModel.achievements.isEmpty {
                Text("아직 배지가 없어요. 열심히 공부하면 쿠키가 배지를 줄 거야! 🐶")
                    .font(.body).foregroundColor(.secondary)
            } else {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 12) {
                    ForEach(viewModel.achievements) { badge in
                        VStack(spacing: 4) {
                            Text("🏆").font(.system(size: 36))
                            Text(badge.title).font(.caption2).multilineTextAlignment(.center)
                        }
                        .padding(8).background(Color.yellow.opacity(0.15)).cornerRadius(12)
                    }
                }
            }
        }
    }

    private var recentSessionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("최근 학습").font(.headline)
                Spacer()
                Menu("필터") {
                    Button("전체") { viewModel.selectedSubjectFilter = nil }
                    ForEach(Subject.allCases, id: \.self) { s in
                        Button(s.rawValue) { viewModel.selectedSubjectFilter = s }
                    }
                }
            }
            ForEach(viewModel.filteredSessions) { session in
                HStack {
                    VStack(alignment: .leading) {
                        Text(session.subject.rawValue).font(.headline)
                        Text(session.topic).font(.caption).foregroundColor(.secondary)
                    }
                    Spacer()
                    Text("\(Int(session.accuracyRate * 100))%")
                        .font(.title3).fontWeight(.bold)
                        .foregroundColor(session.accuracyRate >= 0.8 ? .green : .orange)
                }
                .padding().background(Color(.systemBackground)).cornerRadius(12)
                .shadow(color: .black.opacity(0.04), radius: 2)
            }
        }
    }
}
