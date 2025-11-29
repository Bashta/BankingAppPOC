// SecuritySettingsViewModel.swift
// BankingApp
//
// ViewModel for Security Settings screen managing biometric authentication preferences.
// Allows users to enable/disable Face ID/Touch ID login.

import Foundation
import Combine
import LocalAuthentication

// MARK: - SecuritySettingsViewModel

/// ViewModel managing biometric authentication toggle in Security Settings.
///
/// Responsibilities:
/// - Load and display current biometric availability and preference
/// - Handle toggle to enable/disable biometric authentication
/// - Verify biometric before enabling (user must successfully authenticate)
/// - Persist preference via SecureStorage
/// - Provide user feedback (loading, success, error states)
///
/// Cross-Feature Impact:
/// - Preference stored here affects LoginViewModel's biometric button visibility
/// - Uses shared SecureStorage for preference persistence
///
/// Memory Management:
/// - Weak coordinator reference prevents retain cycles
final class SecuritySettingsViewModel: ObservableObject {

    // MARK: - Published Properties (UI State)

    /// Whether biometric authentication is currently enabled by user preference.
    @Published var biometricEnabled: Bool = false

    /// Type of biometric available on device (Face ID, Touch ID, or none).
    @Published var biometricType: BiometricType = .none

    /// Whether biometric is available on this device.
    @Published var biometricAvailable: Bool = false

    /// Loading state during async operations (toggle, save).
    @Published var isLoading: Bool = false

    /// Error to display (nil = no error).
    @Published var error: Error?

    /// Success message to display (nil = no message).
    @Published var successMessage: String?

    // MARK: - Private Properties

    /// Biometric service for device capability checks and authentication.
    private let biometricService: BiometricServiceProtocol

    /// Secure storage for persisting biometric preference.
    private let secureStorage: SecureStorageProtocol

    /// Weak coordinator reference for navigation (prevents retain cycle).
    private weak var coordinator: MoreCoordinator?

    /// Flag to prevent toggle feedback loop during programmatic updates.
    private var isUpdatingFromLoad: Bool = false

    // MARK: - Initialization

    /// Creates SecuritySettingsViewModel with dependencies.
    ///
    /// - Parameters:
    ///   - biometricService: Service for biometric capability and authentication
    ///   - secureStorage: Service for persisting preference
    ///   - coordinator: MoreCoordinator for navigation (weak reference)
    init(
        biometricService: BiometricServiceProtocol,
        secureStorage: SecureStorageProtocol,
        coordinator: MoreCoordinator
    ) {
        self.biometricService = biometricService
        self.secureStorage = secureStorage
        self.coordinator = coordinator
    }

    // MARK: - Load Methods

    /// Loads biometric availability and user preference.
    ///
    /// Called by SecuritySettingsView on appear via .task modifier.
    /// Updates biometricAvailable, biometricType, and biometricEnabled.
    @MainActor
    func loadBiometricStatus() async {
        isUpdatingFromLoad = true
        defer { isUpdatingFromLoad = false }

        // Check device capability
        biometricAvailable = biometricService.canUseBiometrics()
        biometricType = biometricService.biometricType()

        // Load user preference
        do {
            let preference = try secureStorage.loadBiometricPreference()
            biometricEnabled = preference?.isEnabled ?? false
        } catch {
            // If preference load fails, default to disabled
            biometricEnabled = false
            self.error = error
        }
    }

    // MARK: - Toggle Methods

    /// Toggles biometric authentication preference.
    ///
    /// When enabling:
    /// 1. Verify user can authenticate with biometric (shows system prompt)
    /// 2. On success, save preference as enabled
    /// 3. On failure, show error and keep disabled
    ///
    /// When disabling:
    /// - No verification needed, immediately save preference as disabled
    ///
    /// - Parameter enabled: New enabled state
    @MainActor
    func toggleBiometric(_ enabled: Bool) async {
        // Skip if this is a programmatic update from loadBiometricStatus
        guard !isUpdatingFromLoad else { return }

        // Guard against biometric unavailability
        guard biometricAvailable else {
            error = BiometricError.biometryNotAvailable
            return
        }

        isLoading = true
        error = nil
        successMessage = nil
        defer { isLoading = false }

        do {
            // If enabling, verify biometric first
            if enabled {
                let verified = try await biometricService.authenticate(
                    reason: "Verify your identity to enable biometric authentication"
                )

                guard verified else {
                    // Authentication failed but no error thrown (shouldn't happen)
                    error = BiometricError.authenticationFailed("Unable to verify biometric authentication. Please try again.")
                    // Revert toggle state
                    biometricEnabled = false
                    return
                }
            }

            // Save preference
            let preference = BiometricPreference(isEnabled: enabled)
            try secureStorage.saveBiometricPreference(preference)

            // Update UI state
            biometricEnabled = enabled

            // Success feedback
            let biometricName = biometricTypeName
            successMessage = enabled
                ? "\(biometricName) enabled successfully"
                : "\(biometricName) disabled"

        } catch let laError as LAError {
            // Handle LocalAuthentication-specific errors
            handleLAError(laError, attemptedState: enabled)

        } catch {
            // Other errors (storage, etc.)
            self.error = error
            // Revert toggle state
            biometricEnabled = !enabled
        }
    }

    // MARK: - Error Handling

    /// Handles LocalAuthentication errors during biometric verification.
    private func handleLAError(_ error: LAError, attemptedState: Bool) {
        switch error.code {
        case .userCancel, .systemCancel, .appCancel:
            // User cancelled - silently revert, no error message
            biometricEnabled = !attemptedState

        case .biometryNotAvailable:
            self.error = BiometricError.biometryNotAvailable
            biometricEnabled = false
            biometricAvailable = false

        case .biometryNotEnrolled:
            self.error = BiometricError.biometryNotEnrolled
            biometricEnabled = false
            biometricAvailable = false

        case .biometryLockout:
            self.error = BiometricError.biometryLockout
            biometricEnabled = !attemptedState

        default:
            self.error = BiometricError.authenticationFailed("Unable to verify biometric authentication. Please try again.")
            biometricEnabled = !attemptedState
        }
    }

    // MARK: - UI Helpers

    /// Human-readable name for current biometric type.
    var biometricTypeName: String {
        switch biometricType {
        case .faceID:
            return "Face ID"
        case .touchID:
            return "Touch ID"
        case .none:
            return "Biometric Authentication"
        }
    }

    /// SF Symbol name for current biometric type.
    var biometricIconName: String {
        switch biometricType {
        case .faceID:
            return "faceid"
        case .touchID:
            return "touchid"
        case .none:
            return "lock.fill"
        }
    }

    /// Status text describing current biometric state.
    var statusText: String {
        guard biometricAvailable else {
            return "Biometric authentication not available on this device"
        }

        let name = biometricTypeName
        return biometricEnabled
            ? "\(name) is enabled for login"
            : "\(name) is disabled"
    }

    // MARK: - Error Clearing

    /// Clears the current error.
    func clearError() {
        error = nil
    }

    /// Clears the success message.
    func clearSuccessMessage() {
        successMessage = nil
    }
}
