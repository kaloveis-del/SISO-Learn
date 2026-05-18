import Foundation

final class ManageAPIKeyUseCase {
    private let keychainService: KeychainService

    init(keychainService: KeychainService = KeychainService()) {
        self.keychainService = keychainService
    }

    func save(apiKey: String) throws { try keychainService.save(apiKey: apiKey) }
    func load() throws -> String { try keychainService.load() }
    func hasAPIKey() -> Bool { keychainService.hasAPIKey() }
    func delete() throws { try keychainService.delete() }

    /// Gemini API Key 형식 검증: "AIza"로 시작하는 39자
    func isValidFormat(_ key: String) -> Bool {
        key.hasPrefix("AIza") && key.count == 39
    }
}
