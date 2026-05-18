import SwiftUI

struct ProfileSelectionView: View {

    @State private var viewModel: ProfileViewModel
    @Environment(AppRouter.self) private var router

    private let avatarEmojis = ["🐶","🐱","🐻","🦊","🐼","🐨","🐯","🦁"]

    init(useCase: ManageProfileUseCase) {
        _viewModel = State(initialValue: ProfileViewModel(useCase: useCase))
    }

    var body: some View {

            VStack(spacing: 24) {
                // 쿠키 인사 (Task 6에서 CookieBubbleView로 교체)
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

                // 프로필 그리드
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 3), spacing: 16) {
                    ForEach(viewModel.profiles) { profile in
                        ProfileCardView(
                            profile: profile,
                            avatarEmojis: avatarEmojis,
                            onSelect: {
                                viewModel.selectProfile(profile)
                                router.selectedProfile = profile.name
                                router.navigate(to: .home)
                            },
                            onDelete: { viewModel.deleteProfile(profile) }
                        )
                    }
                }

                if viewModel.canAddProfile {
                    Button {
                        viewModel.isCreatingProfile = true
                    } label: {
                        Label("새 프로필 추가", systemImage: "plus.circle.fill")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.orange)
                }
            }
            .padding()
            .navigationTitle("누가 공부할 거야? 🐶")
            .onAppear { viewModel.loadProfiles() }
            .sheet(isPresented: $viewModel.isCreatingProfile) {
                ProfileCreationView(viewModel: viewModel)
            }
            .alert("오류", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("확인") { viewModel.errorMessage = nil }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
        }
    }

struct ProfileCardView: View {
    let profile: Profile
    let avatarEmojis: [String]
    let onSelect: () -> Void
    let onDelete: () -> Void

    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: 8) {
                Text(avatarEmojis[safe: profile.avatarIndex] ?? "🐶")
                    .font(.system(size: 48))
                Text(profile.name).font(.headline).lineLimit(1)
                Text(profile.gradeLevel.rawValue)
                    .font(.caption).foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button(role: .destructive) { onDelete() } label: {
                Label("삭제", systemImage: "trash")
            }
        }
        .accessibilityLabel("\(profile.name), \(profile.gradeLevel.rawValue)")
        .accessibilityHint("탭하면 이 프로필로 학습을 시작해요")
    }
}
