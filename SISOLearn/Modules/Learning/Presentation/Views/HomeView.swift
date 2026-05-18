import SwiftUI

struct HomeView: View {
    let profile: Profile
    let aiTutor: AITutorProtocol
    @State private var cookieVM = CookieViewModel()
    @State private var selectedSubject: Subject?
    @State private var selectedDifficulty: Difficulty = .normal
    @State private var showDifficultyPicker = false
    @State private var navigateToLearning = false

    private let subjectEmojis: [Subject: String] = [
        .math: "🔢", .english: "🔤", .science: "🔬", .korean: "📖"
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    CookieCharacterView(emotion: cookieVM.currentEmotion)
                    CookieBubbleView(cookieVM: cookieVM)
                    subjectGrid
                    if selectedSubject != nil { difficultySection }
                }
                .padding()
            }
            .navigationTitle("안녕, \(profile.name)! 🐶")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink { SettingsView() } label: {
                        Image(systemName: "gearshape.fill")
                    }
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    NavigationLink { Text("Progress 준비 중") } label: {
                        Image(systemName: "chart.bar.fill")
                    }
                }
            }
            .onAppear { cookieVM.updateForPhase(.greeting, userName: profile.name) }
        }
    }

    private var subjectGrid: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("오늘 뭐 공부할까? 🐾").font(.headline)
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 2), spacing: 12) {
                ForEach(Subject.allCases, id: \.self) { subject in
                    Button {
                        selectedSubject = subject
                        cookieVM.speak("좋아! \(subject.rawValue) 공부 시작이야~ 🐾", emotion: .excited)
                    } label: {
                        VStack(spacing: 8) {
                            Text(subjectEmojis[subject] ?? "📚").font(.system(size: 40))
                            Text(subject.rawValue).font(.headline)
                        }
                        .frame(maxWidth: .infinity).padding()
                        .background(selectedSubject == subject ? Color.orange.opacity(0.2) : Color(.systemBackground))
                        .cornerRadius(16)
                        .shadow(color: .black.opacity(0.06), radius: 4)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(selectedSubject == subject ? Color.orange : Color.clear, lineWidth: 2)
                        )
                    }
                    .buttonStyle(.plain)
                    .frame(minHeight: 44)
                }
            }
        }
    }

    private var difficultySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("난이도 선택").font(.headline)
            Picker("난이도", selection: $selectedDifficulty) {
                ForEach(Difficulty.allCases, id: \.self) { d in
                    Text(d.rawValue).tag(d)
                }
            }
            .pickerStyle(.segmented)
            NavigationLink {
                if let subject = selectedSubject {
                    CookieLearningView(viewModel: LearningSessionViewModel(
                        profile: profile, subject: subject,
                        difficulty: selectedDifficulty, topic: subject.rawValue,
                        startSessionUseCase: StartLearningSessionUseCase(aiTutor: aiTutor),
                        submitAnswerUseCase: SubmitAnswerUseCase(aiTutor: aiTutor),
                        requestHintUseCase: RequestHintUseCase(aiTutor: aiTutor),
                        saveProgressUseCase: SaveProgressUseCase(sessionRepo: SessionRepository()), cookieVM: CookieViewModel()))
                }
            } label: {
                Label("쿠키랑 공부 시작! 🐾", systemImage: "play.fill")
                    .frame(maxWidth: .infinity).frame(height: 50)
            }
            .buttonStyle(.borderedProminent).tint(.orange)
        }
    }
}
