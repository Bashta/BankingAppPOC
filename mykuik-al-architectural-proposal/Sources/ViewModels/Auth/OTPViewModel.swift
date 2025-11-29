// OTPViewModel.swift
// BankingApp
//
// ViewModel for OTP verification screen implementing MVVM pattern with MVVM-C navigation.
// Handles OTP code entry, verification, countdown timer, resend functionality, and error handling.

import Foundation
import Combine
import OSLog

// MARK: - OTPViewModel

/// ViewModel managing OTP verification screen state and logic.
///
/// Responsibilities:
/// - Manage 6-digit OTP code input state
/// - Handle countdown timer for OTP expiration
/// - Verify OTP code via AuthService
/// - Handle success, invalid code, and expiration errors
/// - Support OTP resend functionality
/// - Delegate navigation to AuthCoordinator (weak reference)
///
/// State Management:
/// - OTP success sets AuthService.isAuthenticated = true (for login purpose)
/// - AppCoordinator observes state change → RootView shows MainTabView
/// - Modal dismissal handled by LoginViewModel.showOTP = false
///
/// Timer Pattern:
/// - Uses Timer.publish for countdown updates
/// - Calculates remaining time from OTPReference.expiresAt
/// - Stops timer on dismiss, success, or deinit
///
/// Memory Management:
/// - Weak coordinator reference prevents retain cycles
/// - Timer cancellation in deinit prevents zombie timers
final class OTPViewModel: ObservableObject {

    // MARK: - Published Properties (UI State)

    /// 6-digit OTP code entered by user
    @Published var otpCode: String = ""

    /// Time remaining in seconds until OTP expires
    @Published var timeRemaining: Int = 0

    /// Loading state during async verification
    @Published var isLoading: Bool = false

    /// Error to display in UI (nil = no error)
    @Published var error: Error?

    /// Whether OTP has expired (enables resend button, disables input)
    @Published var isExpired: Bool = false

    /// Whether verification was successful (used for UI feedback before dismissal)
    @Published var isSuccess: Bool = false

    // MARK: - Public Properties

    /// OTP reference containing ID, expiration, and purpose
    let otpReference: OTPReference

    // MARK: - Computed Properties

    /// Formatted time remaining as MM:SS
    var formattedTimeRemaining: String {
        let minutes = timeRemaining / 60
        let seconds = timeRemaining % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    /// Whether OTP code is valid (6 digits)
    var isValidCode: Bool {
        otpCode.count == 6 && otpCode.allSatisfy { $0.isNumber }
    }

    /// Whether verify button should be enabled
    var canVerify: Bool {
        isValidCode && !isExpired && !isLoading
    }

    /// Whether timer is in warning state (less than 60 seconds)
    var isTimerWarning: Bool {
        timeRemaining < 60 && timeRemaining > 0
    }

    /// Purpose-specific display message
    var purposeMessage: String {
        otpReference.purpose.displayMessage
    }

    /// Purpose-specific icon name
    var purposeIcon: String {
        otpReference.purpose.icon
    }

    // MARK: - Private Properties

    /// Auth service for OTP verification
    private let authService: AuthServiceProtocol

    /// Weak coordinator reference for navigation delegation
    private weak var coordinator: AuthCoordinator?

    /// Timer subscription for countdown
    private var timerCancellable: AnyCancellable?

    /// Callback to dismiss OTP modal (called on success or cancel)
    var onDismiss: (() -> Void)?

    // MARK: - Initialization

    /// Creates OTPViewModel with dependencies.
    ///
    /// - Parameters:
    ///   - otpReference: OTP reference containing ID, expiration, and purpose
    ///   - authService: Service for OTP verification
    ///   - coordinator: AuthCoordinator for navigation (weak reference)
    init(
        otpReference: OTPReference,
        authService: AuthServiceProtocol,
        coordinator: AuthCoordinator
    ) {
        self.otpReference = otpReference
        self.authService = authService
        self.coordinator = coordinator

        // Start countdown timer
        startTimer()

        Logger.auth.debug("OTPViewModel initialized for purpose: \(String(describing: otpReference.purpose))")
    }

    deinit {
        // Cancel timer to prevent zombie timers
        timerCancellable?.cancel()
        Logger.auth.debug("OTPViewModel deinit - timer cancelled")
    }

    // MARK: - Timer Methods

    /// Starts the countdown timer from OTP expiration time.
    ///
    /// Timer updates:
    /// - Calculates time remaining from otpReference.expiresAt
    /// - Updates every second
    /// - Sets isExpired = true when timer reaches zero
    /// - Cancels timer when expired
    func startTimer() {
        // Calculate initial time remaining
        updateTimeRemaining()

        // Check if already expired
        if timeRemaining <= 0 {
            handleExpired()
            return
        }

        // Create timer publisher that fires every second
        timerCancellable = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.updateTimeRemaining()
            }
    }

    /// Updates time remaining from OTP expiration date.
    private func updateTimeRemaining() {
        let remaining = Int(otpReference.expiresAt.timeIntervalSinceNow)
        timeRemaining = max(0, remaining)

        if timeRemaining <= 0 {
            handleExpired()
        }
    }

    /// Handles OTP expiration.
    private func handleExpired() {
        timerCancellable?.cancel()
        timerCancellable = nil
        isExpired = true
        error = AuthError.otpExpired
        Logger.auth.info("OTP expired for reference: \(self.otpReference.id)")
    }

    // MARK: - Verification Methods

    /// Verifies the entered OTP code.
    ///
    /// Flow:
    /// 1. Validate code length (6 digits)
    /// 2. Check not expired
    /// 3. Set loading state, clear error
    /// 4. Call authService.verifyOTP(reference, code)
    /// 5. On success: set isSuccess, trigger dismissal
    /// 6. On invalid: show error, clear code, refocus
    /// 7. On expired: show error, enable resend
    ///
    /// State Transition:
    /// - Success: AuthService.isAuthenticated → true (for login) → RootView shows MainTabView
    /// - Invalid: error displayed, code cleared for retry
    /// - Expired: error displayed, resend button enabled
    @MainActor
    func verifyOTP() async {
        guard isValidCode else {
            error = OTPValidationError.invalidLength
            return
        }

        guard !isExpired else {
            error = AuthError.otpExpired
            return
        }

        isLoading = true
        error = nil
        defer { isLoading = false }

        Logger.auth.debug("Verifying OTP code for reference: \(self.otpReference.id)")

        do {
            // Verify OTP via AuthService
            _ = try await authService.verifyOTP(reference: otpReference, code: otpCode)

            // Success - cancel timer
            timerCancellable?.cancel()
            timerCancellable = nil

            // Set success state
            isSuccess = true

            Logger.auth.info("OTP verification successful")

            // Dismiss modal after short delay for UI feedback
            try? await Task.sleep(nanoseconds: 300_000_000) // 300ms

            // Call dismiss callback (LoginViewModel will set showOTP = false)
            onDismiss?()

        } catch let authError as AuthError {
            switch authError {
            case .invalidOTP:
                self.error = authError
                clearCodeForRetry()
                Logger.auth.warning("Invalid OTP code entered")

            case .otpExpired:
                self.error = authError
                handleExpired()
                Logger.auth.warning("OTP expired during verification")

            default:
                self.error = authError
                Logger.auth.error("OTP verification failed: \(authError)")
            }
        } catch {
            self.error = error
            Logger.auth.error("OTP verification error: \(error.localizedDescription)")
        }
    }

    /// Clears OTP code for retry after invalid code error.
    private func clearCodeForRetry() {
        otpCode = ""
    }

    // MARK: - Resend Methods

    /// Requests a new OTP code.
    ///
    /// Note: In real implementation, this would call AuthService to generate new OTP.
    /// For mock, we simulate by extending expiration time.
    ///
    /// Flow:
    /// 1. Set loading state
    /// 2. Simulate network delay
    /// 3. Reset timer to 5 minutes (300 seconds)
    /// 4. Clear error and expired state
    /// 5. Enable input fields
    @MainActor
    func resendOTP() async {
        isLoading = true
        error = nil
        defer { isLoading = false }

        Logger.auth.debug("Requesting new OTP code")

        // Simulate network delay
        try? await Task.sleep(nanoseconds: 500_000_000) // 500ms

        // Reset state for new OTP
        // Note: In real implementation, would get new OTPReference from server
        // For mock, we just reset the timer
        isExpired = false
        clearCodeForRetry()

        // Restart timer with 5 minutes
        // Note: This is a simplification - real impl would use new OTPReference.expiresAt
        timeRemaining = 300 // 5 minutes

        timerCancellable = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self else { return }
                self.timeRemaining -= 1
                if self.timeRemaining <= 0 {
                    self.handleExpired()
                }
            }

        Logger.auth.info("New OTP code sent, timer reset to 5 minutes")
    }

    // MARK: - Navigation Methods

    /// Cancels OTP verification and dismisses modal.
    ///
    /// Called when user taps cancel or swipes to dismiss.
    /// LoginViewModel observes showOTP binding and handles dismissal.
    func cancel() {
        timerCancellable?.cancel()
        timerCancellable = nil
        onDismiss?()
        Logger.auth.debug("OTP verification cancelled by user")
    }
}

// MARK: - OTPPurpose Extensions

extension OTPPurpose {
    /// Purpose-specific display message for OTP screen
    var displayMessage: String {
        switch self {
        case .login:
            return "Enter OTP to complete login"
        case .transfer:
            return "Enter OTP to confirm transfer"
        case .cardPINChange:
            return "Enter OTP to change your card PIN"
        case .passwordReset:
            return "Enter OTP to reset your password"
        case .changePIN:
            return "Enter OTP to change your PIN"
        }
    }

    /// SF Symbol icon for this OTP purpose
    var icon: String {
        switch self {
        case .login:
            return "lock.shield.fill"
        case .transfer:
            return "arrow.left.arrow.right.circle.fill"
        case .cardPINChange:
            return "creditcard.fill"
        case .passwordReset:
            return "key.fill"
        case .changePIN:
            return "key.fill"
        }
    }
}

// MARK: - OTP Validation Error

/// Errors specific to OTP input validation
enum OTPValidationError: Error, LocalizedError {
    case invalidLength
    case nonNumericCharacters

    var errorDescription: String? {
        switch self {
        case .invalidLength:
            return "Please enter all 6 digits"
        case .nonNumericCharacters:
            return "OTP must contain only numbers"
        }
    }
}

// MARK: - AuthError Extension for User-Friendly Messages

extension AuthError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .invalidCredentials:
            return "Invalid username or password"
        case .invalidOTP:
            return "Invalid OTP code. Please try again."
        case .otpExpired:
            return "OTP code expired. Please request a new code."
        case .sessionExpired:
            return "Your session has expired. Please log in again."
        case .userNotFound:
            return "User not found"
        case .notAuthenticated:
            return "You must be logged in to perform this action"
        case .invalidEmail:
            return "Please enter a valid email address"
        case .invalidToken:
            return "Invalid or expired reset token"
        case .passwordTooWeak:
            return "Password must be at least 8 characters"
        case .invalidPIN:
            return "Invalid PIN"
        case .pinTooShort:
            return "PIN must be at least 4 digits"
        }
    }
}
