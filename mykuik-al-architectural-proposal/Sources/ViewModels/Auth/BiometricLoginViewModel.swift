// BiometricLoginViewModel.swift
// BankingApp
//
// ViewModel for standalone biometric authentication screen.
// Used when user is routed directly to biometric authentication.

import Foundation
import Combine
import OSLog

// MARK: - BiometricLoginViewModel

/// ViewModel managing standalone biometric login screen.
///
/// Use Cases:
/// - Quick re-authentication after session timeout
/// - Deep link to biometric login (bankapp://auth/biometric)
/// - Direct biometric auth without username/password form
///
/// Flow:
/// 1. View appears → auto-trigger biometric prompt (or user taps button)
/// 2. BiometricService.authenticate() shows system prompt
/// 3. On success → AuthService.loginWithBiometric()
/// 4. If OTP required → present OTP modal
/// 5. On failure → show error with password fallback option
///
/// State Management:
/// - Published properties for reactive UI updates
/// - Weak coordinator reference for navigation
/// - Proper loading state during async operations
final class BiometricLoginViewModel: ObservableObject {

    // MARK: - Published Properties (UI State)

    /// Whether biometric authentication is in progress
    @Published var isAuthenticating: Bool = false

    /// Error to display (nil = no error)
    @Published var error: BiometricError?

    /// Type of biometric available on device
    @Published var biometricType: BiometricType = .none

    /// Whether biometric is available on this device
    @Published var canUseBiometrics: Bool = false

    /// Controls OTP modal presentation
    @Published var showOTP: Bool = false

    /// Whether to show password fallback option
    @Published var showPasswordFallback: Bool = false

    // MARK: - Private Properties

    private let authService: AuthServiceProtocol
    private let biometricService: BiometricServiceProtocol
    private weak var coordinator: AuthCoordinator?

    /// OTP reference when login requires multi-factor authentication
    private var otpReference: OTPReference?

    // MARK: - Computed Properties

    /// Returns the OTP reference for modal presentation
    var currentOTPReference: OTPReference? {
        otpReference
    }

    /// Display name for the biometric type
    var biometricTypeName: String {
        switch biometricType {
        case .faceID:
            return "Face ID"
        case .touchID:
            return "Touch ID"
        case .none:
            return "Biometric"
        }
    }

    /// SF Symbol name for the biometric type
    var biometricIcon: String {
        switch biometricType {
        case .faceID:
            return "faceid"
        case .touchID:
            return "touchid"
        case .none:
            return "key.fill"
        }
    }

    // MARK: - Initialization

    /// Creates BiometricLoginViewModel with dependencies.
    ///
    /// - Parameters:
    ///   - authService: Service for authentication operations
    ///   - biometricService: Service for biometric authentication
    ///   - coordinator: AuthCoordinator for navigation (weak reference)
    init(
        authService: AuthServiceProtocol,
        biometricService: BiometricServiceProtocol,
        coordinator: AuthCoordinator
    ) {
        self.authService = authService
        self.biometricService = biometricService
        self.coordinator = coordinator
    }

    // MARK: - Public Methods

    /// Checks and updates biometric availability.
    ///
    /// Called on view appear via .task modifier.
    func checkBiometricAvailability() {
        canUseBiometrics = biometricService.canUseBiometrics()
        if canUseBiometrics {
            biometricType = biometricService.biometricType()
        } else {
            biometricType = .none
        }

        Logger.biometric.debug("BiometricLoginVM check: available=\(self.canUseBiometrics), type=\(String(describing: self.biometricType))")
    }

    /// Performs biometric authentication.
    ///
    /// Flow:
    /// 1. Set loading state, clear error
    /// 2. Call biometricService.authenticate() - shows system prompt
    /// 3. On success: call authService.loginWithBiometric()
    /// 4. Handle OTP if required, otherwise auth completes automatically
    /// 5. On failure: show user-friendly error with fallback option
    @MainActor
    func authenticateWithBiometric() async {
        guard canUseBiometrics else {
            Logger.biometric.error("Biometric unavailable, cannot authenticate")
            return
        }

        guard !isAuthenticating else {
            Logger.biometric.debug("Already authenticating, ignoring duplicate request")
            return
        }

        isAuthenticating = true
        error = nil
        showPasswordFallback = false
        defer { isAuthenticating = false }

        do {
            Logger.biometric.info("Starting biometric authentication")

            // Show system biometric prompt
            _ = try await biometricService.authenticate(reason: "Log in to your account")

            Logger.biometric.debug("Biometric verified, calling AuthService")

            // Biometric succeeded - complete login
            let result = try await authService.loginWithBiometric()

            // Check if OTP is required (AC #4)
            if result.requiresOTP, let reference = result.otpReference {
                otpReference = reference
                showOTP = true
                Logger.auth.info("Biometric login requires OTP verification")
            }
            // Otherwise auth completes automatically via AuthService state change

            Logger.auth.info("Biometric authentication flow completed successfully")

        } catch let biometricError as BiometricError {
            handleBiometricError(biometricError)
        } catch {
            // Non-biometric error (from authService.loginWithBiometric)
            self.error = .authenticationFailed(error.localizedDescription)
            self.showPasswordFallback = true
            Logger.auth.error("Biometric login service error: \(error.localizedDescription)")
        }
    }

    /// Navigates to password fallback (standard login).
    ///
    /// Called when user chooses "Use Password" option after biometric failure.
    func fallbackToPassword() {
        Logger.biometric.info("User selected password fallback")
        // Pop back to login screen (which shows username/password form)
        coordinator?.popToRoot()
    }

    /// Retries biometric authentication.
    ///
    /// Called when user wants to try biometric again after error.
    func retryBiometric() {
        error = nil
        showPasswordFallback = false
        Task {
            await authenticateWithBiometric()
        }
    }

    /// Clears the current error.
    func clearError() {
        error = nil
        showPasswordFallback = false
    }

    // MARK: - Private Methods

    private func handleBiometricError(_ biometricError: BiometricError) {
        Logger.biometric.error("Biometric error: \(biometricError.userFriendlyMessage)")

        switch biometricError {
        case .userCancelled:
            // User cancelled - don't show error, just return
            Logger.biometric.debug("User cancelled biometric prompt")
            return

        case .userFallback:
            // User chose "Use Password" on system prompt
            showPasswordFallback = true
            return

        default:
            // Show error and offer fallback
            self.error = biometricError
            self.showPasswordFallback = biometricError.shouldOfferPasswordFallback
        }
    }
}
