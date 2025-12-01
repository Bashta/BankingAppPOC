import Foundation
import Security

final class KeychainSecureStorage: SecureStorageProtocol {

    // MARK: - Constants

    private enum Keys {
        static let biometricPreference = "com.bankingapp.biometricPreference"
    }

    // MARK: - Private Generic Data Operations

    private func save(_ data: Data, forKey key: String) throws {
        // Create query dictionary
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data
        ]

        // Delete any existing item
        SecItemDelete(query as CFDictionary)

        // Add new item
        let status = SecItemAdd(query as CFDictionary, nil)

        guard status == errSecSuccess else {
            throw KeychainError.unableToSave(status)
        }
    }

    private func load(forKey key: String) throws -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        if status == errSecItemNotFound {
            return nil
        }

        guard status == errSecSuccess else {
            throw KeychainError.unknown(status)
        }

        guard let data = result as? Data else {
            throw KeychainError.invalidData
        }

        return data
    }

    // MARK: - Biometric Preference Operations

    func saveBiometricPreference(_ preference: BiometricPreference) throws {
        let encoder = JSONEncoder()
        let data = try encoder.encode(preference)
        try save(data, forKey: Keys.biometricPreference)
    }

    func loadBiometricPreference() throws -> BiometricPreference? {
        guard let data = try load(forKey: Keys.biometricPreference) else {
            return nil
        }
        let decoder = JSONDecoder()
        return try decoder.decode(BiometricPreference.self, from: data)
    }
}

enum KeychainError: Error {
    case unableToSave(OSStatus)
    case invalidData
    case unknown(OSStatus)
}
