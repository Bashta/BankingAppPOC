import Foundation

protocol SecureStorageProtocol {
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
}
