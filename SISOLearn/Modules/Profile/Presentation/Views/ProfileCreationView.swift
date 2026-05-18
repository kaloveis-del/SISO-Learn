import SwiftUI

struct ProfileCreationView: View {

    @Bindable var viewModel: ProfileViewModel
    @Environment(\.dismiss) private var dismiss

    private let avatarEmojis = ["🐶","🐱","🐻","🦊","🐼","🐨","🐯","🦁"]

    var body: some View {
        NavigationStack {
            Form {
                Section("이름") {
                    TextField("이름을 입력해줘", text: $viewModel.newProfileName)
                        .textInputAutocapitalization(.never)
                }

                Section("학년") {
                    Picker("학년", selection: $viewModel.newProfileGrade) {
                        ForEach(GradeLevel.allCases, id: \.self) { grade in
                            Text(grade.rawValue).tag(grade)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section("아바타") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 12) {
                        ForEach(avatarEmojis.indices, id: \.self) { index in
                            Button {
                                viewModel.newProfileAvatarIndex = index
                            } label: {
                                Text(avatarEmojis[index])
                                    .font(.system(size: 40))
                                    .frame(width: 60, height: 60)
                                    .background(
                                        viewModel.newProfileAvatarIndex == index
                                            ? Color.orange.opacity(0.3) : Color.clear
                                    )
                                    .cornerRadius(12)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
            .navigationTitle("새 프로필 만들기")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("완료") { viewModel.createProfile() }
                        .disabled(!viewModel.isNewProfileValid)
                        .fontWeight(.semibold)
                }
            }
        }
    }
}
