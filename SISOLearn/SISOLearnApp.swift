import SwiftUI

@main
struct SISOLearnApp: App {
    @State private var networkMonitor = NetworkMonitor.shared
    @State private var selectedProfile: Profile? = nil

    var body: some Scene {
        WindowGroup {
            if let profile = selectedProfile {
                HomeWrapper(profile: profile, onBack: { selectedProfile = nil })
                    .environment(networkMonitor)
            } else {
                ProfileSelectionScreen(onProfileSelected: { profile in
                    selectedProfile = profile
                })
                .environment(networkMonitor)
            }
        }
    }
}

/// HomeView를 감싸서 매번 최신 API Key로 aiTutor를 생성
struct HomeWrapper: View {
    let profile: Profile
    let onBack: () -> Void
    @State private var apiKey: String = ""

    var body: some View {
        NavigationStack {
            let aiTutor = GeminiAITutor(apiKey: apiKey)
            HomeView(profile: profile, aiTutor: aiTutor)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("← 프로필") { onBack() }
                    }
                }
        }
        .onAppear {
            // 매번 화면 진입 시 최신 API Key를 Keychain에서 읽음
            apiKey = (try? KeychainService().load()) ?? ""
        }
    }
}

struct ProfileSelectionScreen: View {
    let onProfileSelected: (Profile) -> Void
    @State private var viewModel = ProfileViewModel(useCase: ManageProfileUseCase(repository: ProfileRepository()))

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                HStack(spacing: 12) {
                    Text("🐶").font(.system(size: 56))
                    VStack(alignment: .leading) {
                        Text("안녕! 나는 쿠키야!")
                            .font(.title2).fontWeight(.bold)
                        Text("오늘도 같이 공부해볼까? 멍멍!")
                            .font(.body).foregroundColor(.secondary)
                    }
                    Spacer()
                }
                .padding()
                .background(Color.orange.opacity(0.1))
                .cornerRadius(16)

                let avatarEmojis = ["🐶","🐱","🐻","🦊","🐼","🐨","🐯","🦁"]
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 3), spacing: 16) {
                    ForEach(viewModel.profiles) { profile in
                        Button {
                            viewModel.selectProfile(profile)
                            onProfileSelected(profile)
                        } label: {
                            VStack(spacing: 8) {
                                Text(avatarEmojis[safe: profile.avatarIndex] ?? "🐶")
                                    .font(.system(size: 48))
                                Text(profile.name).font(.headline).lineLimit(1)
                                Text(profile.gradeLevel.rawValue)
                                    .font(.caption).foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity).padding()
                            .background(Color(.systemBackground))
                            .cornerRadius(16)
                            .shadow(color: .black.opacity(0.08), radius: 4)
                        }
                        .buttonStyle(.plain)
                    }
                }

                if viewModel.canAddProfile {
                    Button {
                        viewModel.isCreatingProfile = true
                    } label: {
                        Label("새 프로필 추가", systemImage: "plus.circle.fill")
                            .font(.headline)
                            .frame(maxWidth: .infinity).frame(height: 50)
                    }
                    .buttonStyle(.borderedProminent).tint(.orange)
                }
            }
            .padding()
            .navigationTitle("누가 공부할 거야? 🐶")
            .onAppear { viewModel.loadProfiles() }
            .sheet(isPresented: $viewModel.isCreatingProfile) {
                ProfileCreationView(viewModel: viewModel)
            }
        }
    }
}
