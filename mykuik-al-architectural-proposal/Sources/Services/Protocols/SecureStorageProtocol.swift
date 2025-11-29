import Foundation

protocol SecureStorageProtocol {
    // MARK: - Generic Data Operations

    func save(_ data: Data, forKey key: String) throws
    func load(forKey key: String) throws -> Data?
    func delete(forKey key: String) throws

    // MARK: - Biometric Preference Operations

    /// Saves biometric authentication preference.
    ///
    /// - Parameter preference: The user's biometric preference to save
    /// - Throws: Storage error if save fails
    func saveBiometricPreference(_ preference: BiometricPreference) throws

    /// Loads biometric authentication preference.
    ///
    /// - Returns: The stored preference, or nil if not set
    /// - Throws: Storage error if load fails (except for not found)
    func loadBiometricPreference() throws -> BiometricPreference?

    /// Deletes biometric authentication preference.
    ///
    /// - Throws: Storage error if delete fails
    func deleteBiometricPreference() throws
}
