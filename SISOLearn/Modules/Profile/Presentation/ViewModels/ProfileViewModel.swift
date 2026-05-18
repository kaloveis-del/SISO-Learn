import SwiftUI
import Observation

@MainActor
@Observable
final class ProfileViewModel {

    var profiles: [Profile] = []
    var selectedProfile: Profile?
    var isCreatingProfile = false
    var newProfileName = ""
    var newProfileGrade: GradeLevel = .grade5Elementary
    var newProfileAvatarIndex = 0
    var isLoading = false
    var errorMessage: String?

    var canAddProfile: Bool { profiles.count < AppConstants.maxProfileCount }
    var isNewProfileValid: Bool { !newProfileName.isBlank }

    private let useCase: ManageProfileUseCase

    init(useCase: ManageProfileUseCase) {
        self.useCase = useCase
    }

    func loadProfiles() {
        isLoading = true
        Task {
            do {
                profiles = try await useCase.fetchAll()
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }

    func selectProfile(_ profile: Profile) {
        selectedProfile = profile
        Task { try? await useCase.updateLastActive(profileId: profile.id) }
    }

    func createProfile() {
        guard isNewProfileValid else { return }
        Task {
            do {
                let profile = try await useCase.create(
                    name: newProfileName,
                    gradeLevel: newProfileGrade,
                    avatarIndex: newProfileAvatarIndex
                )
                profiles.append(profile)
                newProfileName = ""
                newProfileGrade = .grade5Elementary
                newProfileAvatarIndex = 0
                isCreatingProfile = false
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    func deleteProfile(_ profile: Profile) {
        Task {
            do {
                try await useCase.delete(profileId: profile.id)
                profiles.removeAll { $0.id == profile.id }
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}
