import Foundation

/// Model for storing user's biometric authentication preference.
///
/// This preference controls whether Face ID/Touch ID is shown on the login screen.
/// Stored via SecureStorageProtocol (Keychain in production).
///
/// Usage:
/// - SecuritySettingsViewModel saves preference when user toggles biometric
/// - LoginViewModel loads preference to determine biometric button visibility
struct BiometricPreference: Codable, Equatable {
    /// Whether biometric authentication is enabled by the user.
    let isEnabled: Bool

    /// Creates a BiometricPreference with specified enabled state.
    ///
    /// - Parameter isEnabled: Whether biometric authentication is enabled.
    ///   Defaults to false for security (opt-in).
    init(isEnabled: Bool = false) {
        self.isEnabled = isEnabled
    }
}
