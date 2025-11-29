// LoginViewModel.swift
// BankingApp
//
// ViewModel for the login screen implementing MVVM pattern with MVVM-C navigation.
// Handles username/password authentication, biometric login, and OTP flow initiation.

import Foundation
import SwiftUI
import Combine
import LocalAuthentication
import OSLog

// MARK: - LoginViewModel

/// ViewModel managing login screen state and authentication logic.
///
/// Responsibilities:
/// - Manage form state (username, password, loading, error)
/// - Handle username/password login via AuthService
/// - Handle biometric login via BiometricService + AuthService
/// - Check and expose biometric availability
/// - Manage OTP modal presentation when login requires MFA
/// - Delegate navigation to AuthCoordinator (weak reference)
///
/// State Management:
/// - Login success sets AuthService.isAuthenticated = true
/// - AppCoordinator observes state change → RootView shows MainTabView
/// - No manual navigation needed after successful authentication
///
/// Memory Management:
/// - Weak coordinator reference prevents retain cycles
/// - View holds @ObservedObject reference to this ViewModel
final class LoginViewModel: ObservableObject {

    // MARK: - Published Properties (UI State)

    /// Username input binding for TextField
    @Published var username: String = ""

    /// Password input binding for SecureField
    @Published var password: String = ""

    /// Loading state during async operations
    @Published var isLoading: Bool = false

    /// Error to display in UI (nil = no error)
    @Published var error: Error?

    /// Controls OTP modal presentation
    @Published var showOTP: Bool = false

    /// Whether biometric login is available on device
    @Published var canUseBiometrics: Bool = false

    /// Type of biometric available (faceID, touchID, or none)
    @Published var biometricType: BiometricType = .none

    // MARK: - Private Properties

    /// OTP reference received when login requires multi-factor authentication
    private var otpReference: OTPReference?

    /// Auth service for authentication operations (exposed for OTPViewModel creation)
    let authService: AuthServiceProtocol

    /// Biometric service for Face ID / Touch ID
    private let biometricService: BiometricServiceProtocol

    /// Weak coordinator reference for navigation delegation
    /// Note: Made internal (not private) to allow LoginView to pass to OTPViewModel creation
    weak var coordinator: AuthCoordinator?

    // MARK: - Computed Properties

    /// Form validation - both username and password must be non-empty
    var isValid: Bool {
        !username.trimmingCharacters(in: .whitespaces).isEmpty &&
        !password.isEmpty
    }

    /// Returns the OTP reference for modal presentation
    var currentOTPReference: OTPReference? {
        otpReference
    }

    /// Creates an OTPViewModel for the current OTP reference.
    /// Used by LoginView to present OTP modal.
    ///
    /// - Parameters:
    ///   - coordinator: AuthCoordinator for navigation
    /// - Returns: Configured OTPViewModel or nil if no OTP reference
    func createOTPViewModel(coordinator: AuthCoordinator) -> OTPViewModel? {
        guard let reference = otpReference else { return nil }

        let viewModel = OTPViewModel(
            otpReference: reference,
            authService: authService,
            coordinator: coordinator
        )

        // Wire up dismiss callback to close the modal
        viewModel.onDismiss = { [weak self] in
            self?.showOTP = false
        }

        return viewModel
    }

    // MARK: - Initialization

    /// Creates LoginViewModel with dependencies.
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

    // MARK: - Authentication Methods

    /// Performs username/password login.
    ///
    /// Flow:
    /// 1. Set loading state, clear previous error
    /// 2. Call authService.login(username:password:)
    /// 3. If result.requiresOTP: store reference, set showOTP = true
    /// 4. If no OTP required: auth completes automatically via AuthService state change
    /// 5. On error: set error property for UI display
    ///
    /// State Transition:
    /// - Success (no OTP): AuthService.isAuthenticated → true → RootView shows MainTabView
    /// - Success (OTP required): showOTP → true → OTP modal presented
    /// - Failure: error → displayed in UI
    @MainActor
    func login() async {
        guard isValid else { return }

        isLoading = true
        error = nil
        defer { isLoading = false }

        do {
            let result = try await authService.login(
                username: username.trimmingCharacters(in: .whitespaces),
                password: password
            )

            // Check if OTP required for multi-factor authentication
            if result.requiresOTP, let reference = result.otpReference {
                otpReference = reference
                showOTP = true
                Logger.auth.debug("Login requires OTP, presenting modal")
            }
            // If no OTP required, authentication completes automatically
            // AuthService sets isAuthenticated = true
            // AppCoordinator observes state change
            // RootView transitions to MainTabView

        } catch {
            // Set generic error message - don't reveal if username or password is wrong
            self.error = error
            Logger.auth.error("Login failed: \(error.localizedDescription)")
        }
    }

    /// Performs biometric (Face ID / Touch ID) login.
    ///
    /// Flow:
    /// 1. Guard biometric availability
    /// 2. Set loading state, clear error
    /// 3. Call biometricService.authenticate() for system prompt
    /// 4. On biometric success: call authService.loginWithBiometric()
    /// 5. Auth completes automatically via AuthService state change
    ///
    /// Error Handling:
    /// - User cancellation: Silent return, no error shown
    /// - Other failures: User-friendly error message
    @MainActor
    func loginWithBiometric() async {
        guard canUseBiometrics else { return }

        isLoading = true
        error = nil
        defer { isLoading = false }

        do {
            // Authenticate with biometric (shows system Face ID / Touch ID prompt)
            _ = try await biometricService.authenticate(reason: "Log in to your account")

            // Biometric success - complete login with stored credentials
            let result = try await authService.loginWithBiometric()

            // Check if OTP required (unlikely for biometric, but handle it)
            if result.requiresOTP, let reference = result.otpReference {
                otpReference = reference
                showOTP = true
            }
            // Otherwise, authentication completes automatically via AuthService state change

            Logger.auth.debug("Biometric login successful")

        } catch let laError as LAError {
            // Handle LocalAuthentication-specific errors
            switch laError.code {
            case .userCancel, .systemCancel, .appCancel:
                // User cancelled - don't show error, just return
                Logger.auth.debug("Biometric cancelled by user/system")
                return

            case .biometryNotAvailable, .biometryNotEnrolled:
                // Biometric not available (shouldn't happen since we check canUseBiometrics)
                self.error = NSError(
                    domain: "BiometricAuth",
                    code: laError.code.rawValue,
                    userInfo: [NSLocalizedDescriptionKey: "Biometric authentication is not available"]
                )

            case .biometryLockout:
                self.error = NSError(
                    domain: "BiometricAuth",
                    code: laError.code.rawValue,
                    userInfo: [NSLocalizedDescriptionKey: "Biometric authentication is locked. Please use your password."]
                )

            default:
                // Generic biometric failure
                self.error = NSError(
                    domain: "BiometricAuth",
                    code: laError.code.rawValue,
                    userInfo: [NSLocalizedDescriptionKey: "Biometric authentication failed. Please try again or use your password."]
                )
            }

            Logger.biometric.error("Biometric error: \(laError.localizedDescription)")

        } catch {
            // Non-biometric error (from authService.loginWithBiometric)
            self.error = error
            Logger.auth.error("Biometric login failed: \(error.localizedDescription)")
        }
    }

    // MARK: - Navigation Methods

    /// Navigates to forgot password screen.
    ///
    /// Delegates to AuthCoordinator via weak reference.
    func navigateToForgotPassword() {
        coordinator?.push(.forgotPassword)
    }

    // MARK: - Biometric Availability

    /// Checks and updates biometric availability state.
    ///
    /// Called on view appear via .task modifier.
    /// Updates canUseBiometrics and biometricType for UI.
    func checkBiometricAvailability() {
        canUseBiometrics = biometricService.canUseBiometrics()
        if canUseBiometrics {
            biometricType = biometricService.biometricType()
        } else {
            biometricType = .none
        }

        Logger.biometric.debug("Biometric check: available=\(self.canUseBiometrics), type=\(String(describing: self.biometricType))")
    }

    // MARK: - Error Clearing

    /// Clears the current error.
    ///
    /// Called when user edits username or password fields.
    func clearError() {
        error = nil
    }
}
