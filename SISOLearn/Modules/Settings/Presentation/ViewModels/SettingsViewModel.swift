import SwiftUI
import Observation

@MainActor
@Observable
final class SettingsViewModel {

    var apiKeyInput: String = ""
    var isAPIKeyVisible: Bool = false
    var isAPIKeyValid: Bool = false
    var isSaving: Bool = false
    var hasStoredAPIKey: Bool = false
    var alertMessage: String?
    var showAlert: Bool = false

    private let useCase: ManageAPIKeyUseCase

    init(useCase: ManageAPIKeyUseCase = ManageAPIKeyUseCase()) {
        self.useCase = useCase
    }

    func onAppear() {
        hasStoredAPIKey = useCase.hasAPIKey()
    }

    func validateFormat() {
        isAPIKeyValid = useCase.isValidFormat(apiKeyInput)
    }

    func saveAPIKey() {
        guard isAPIKeyValid else { return }
        isSaving = true
        do {
            try useCase.save(apiKey: apiKeyInput)
            hasStoredAPIKey = true
            apiKeyInput = ""
            alertMessage = "API 키가 저장됐어요! 🐶"
            showAlert = true
        } catch {
            alertMessage = error.localizedDescription
            showAlert = true
        }
        isSaving = false
    }

    func deleteAPIKey() {
        do {
            try useCase.delete()
            hasStoredAPIKey = false
            alertMessage = "API 키가 삭제됐어요"
            showAlert = true
        } catch {
            alertMessage = error.localizedDescription
            showAlert = true
        }
    }
}
