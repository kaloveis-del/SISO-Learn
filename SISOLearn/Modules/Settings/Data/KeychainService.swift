import Security
import Foundation

final class KeychainService {

    func save(apiKey: String) throws {
        guard let data = apiKey.data(using: .utf8) else {
            throw KeychainError.encodingFailed
        }
        try? delete()
        let query: [String: Any] = [
            kSecClass as String:           kSecClassGenericPassword,
            kSecAttrService as String:     KeychainKeys.service,
            kSecAttrAccount as String:     KeychainKeys.geminiAPIKey,
            kSecValueData as String:       data,
            kSecAttrAccessible as String:  kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else { throw KeychainError.saveFailed(status) }
    }

    func load() throws -> String {
        let query: [String: Any] = [
            kSecClass as String:        kSecClassGenericPassword,
            kSecAttrService as String:  KeychainKeys.service,
            kSecAttrAccount as String:  KeychainKeys.geminiAPIKey,
            kSecReturnData as String:   true,
            kSecMatchLimit as String:   kSecMatchLimitOne
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess,
              let data = result as? Data,
              let apiKey = String(data: data, encoding: .utf8) else {
            throw KeychainError.notFound
        }
        return apiKey
    }

    func hasAPIKey() -> Bool { (try? load()) != nil }

    func delete() throws {
        let query: [String: Any] = [
            kSecClass as String:        kSecClassGenericPassword,
            kSecAttrService as String:  KeychainKeys.service,
            kSecAttrAccount as String:  KeychainKeys.geminiAPIKey
        ]
        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.deleteFailed(status)
        }
    }
}

enum KeychainError: LocalizedError {
    case encodingFailed
    case saveFailed(OSStatus)
    case notFound
    case deleteFailed(OSStatus)

    var errorDescription: String? {
        switch self {
        case .encodingFailed:           return "API 키 인코딩에 실패했어요"
        case .saveFailed(let s):        return "저장 실패 (코드: \(s))"
        case .notFound:                 return "저장된 API 키가 없어요"
        case .deleteFailed(let s):      return "삭제 실패 (코드: \(s))"
        }
    }
}
