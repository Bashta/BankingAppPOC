// ChangePINViewModel.swift
// Story 2.10: Implement Change PIN Flow

import Foundation
import SwiftUI
import Combine
import OSLog

/// ViewModel for the change PIN flow
/// Handles PIN validation, OTP verification, submission, and navigation
///
/// AC: #1 - Required @Published properties
/// AC: #2 - PIN validation computed properties
/// AC: #3 - changePIN async method with OTP flow
/// AC: #4 - verifyOTP async method
/// AC: #5 - Navigation methods
final class ChangePINViewModel: ObservableObject {
    // MARK: - Published Properties (AC: #1)

    /// User's current PIN input
    @Published var oldPIN: String = ""

    /// User's new PIN input
    @Published var newPIN: String = ""

    /// User's confirm PIN input
    @Published var confirmPIN: String = ""

    /// Loading state during PIN change or OTP verification
    @Published var isChanging: Bool = false

    /// Error state for failed operations
    @Published var error: Error?

    /// Controls OTP modal presentation
    @Published var showOTP: Bool = false

    /// OTP reference received after PIN validation
    @Published var otpReference: OTPReference?

    /// Tracks whether the PIN has been successfully changed
    @Published var hasChanged: Bool = false

    /// OTP code input for verification
    @Published var otpCode: String = ""

    // MARK: - Dependencies (AC: #1)

    private let authService: AuthServiceProtocol
    weak var coordinator: MoreCoordinator?

    // MARK: - Validation Computed Properties (AC: #2)

    /// Old PIN is valid: exactly 4 numeric digits
    var isOldPINValid: Bool {
        oldPIN.count == 4 && oldPIN.allSatisfy { $0.isNumber }
    }

    /// New PIN is valid: exactly 4 numeric digits
    var isNewPINValid: Bool {
        newPIN.count == 4 && newPIN.allSatisfy { $0.isNumber }
    }

    /// Confirm PIN matches new PIN (and new PIN is not empty)
    var doPINsMatch: Bool {
        !newPIN.isEmpty && newPIN == confirmPIN
    }

    /// New PIN differs from old PIN
    var pinsDiffer: Bool {
        !newPIN.isEmpty && !oldPIN.isEmpty && newPIN != oldPIN
    }

    /// Form is valid when all conditions are met
    var isFormValid: Bool {
        isOldPINValid && isNewPINValid && doPINsMatch && pinsDiffer
    }

    // MARK: - Initialization (AC: #1)

    /// Creates a ChangePINViewModel with required dependencies
    /// - Parameters:
    ///   - authService: Service for authentication operations
    ///   - coordinator: MoreCoordinator for navigation (weak reference to prevent retain cycles)
    init(authService: AuthServiceProtocol, coordinator: MoreCoordinator?) {
        self.authService = authService
        self.coordinator = coordinator
    }

    // MARK: - Actions (AC: #3)

    /// Initiates PIN change via the auth service
    /// On success, receives OTPReference and shows OTP modal for verification
    ///
    /// AC: #3 Requirements:
    /// - Sets isChanging = true before auth call
    /// - Uses defer to ensure isChanging = false after completion
    /// - Clears previous error before attempt
    /// - Calls authService.changePIN(oldPIN:, newPIN:)
    /// - On success (returns OTPReference): sets otpReference and showOTP = true
    /// - On error: sets error property
    /// - Includes debug logging
    @MainActor
    func changePIN() async {
        isChanging = true
        error = nil
        defer { isChanging = false }

        Logger.auth.debug("[ChangePINViewModel] Attempting to change PIN")

        do {
            let reference = try await authService.changePIN(oldPIN: oldPIN, newPIN: newPIN)

            otpReference = reference
            showOTP = true
            otpCode = "" // Clear any previous OTP code

            Logger.auth.info("[ChangePINViewModel] PIN change initiated, OTP required")

        } catch {
            self.error = error
            Logger.auth.error("[ChangePINViewModel] changePIN failed: \(error.localizedDescription)")
        }
    }

    // MARK: - OTP Verification (AC: #4)

    /// Verifies the OTP code to complete PIN change
    ///
    /// AC: #4 Requirements:
    /// - Calls authService.verifyOTP(reference:, code:)
    /// - On success: sets showOTP = false, sets hasChanged = true
    /// - On error: sets error property with user-friendly message
    /// - Includes debug logging
    @MainActor
    func verifyOTP(_ code: String) async {
        guard let reference = otpReference else {
            Logger.auth.error("[ChangePINViewModel] verifyOTP called without OTP reference")
            return
        }

        isChanging = true
        error = nil
        defer { isChanging = false }

        Logger.auth.debug("[ChangePINViewModel] Verifying OTP for PIN change")

        do {
            _ = try await authService.verifyOTP(reference: reference, code: code)

            showOTP = false
            hasChanged = true
            otpReference = nil
            otpCode = ""

            Logger.auth.info("[ChangePINViewModel] PIN changed successfully after OTP verification")

        } catch {
            self.error = error
            Logger.auth.error("[ChangePINViewModel] OTP verification failed: \(error.localizedDescription)")
        }
    }

    // MARK: - Navigation (AC: #5)

    /// Navigates back to the previous screen
    /// Called via back navigation or cancel
    func navigateBack() {
        Logger.auth.debug("[ChangePINViewModel] Navigating back")
        coordinator?.pop()
    }

    /// Navigates back after successful PIN change
    /// Called when user taps "Done" on success view
    func dismissAfterSuccess() {
        Logger.auth.debug("[ChangePINViewModel] Dismissing after success")
        coordinator?.pop()
    }

    /// Dismisses the OTP modal without completing
    /// Called when user cancels OTP entry
    func dismissOTP() {
        Logger.auth.debug("[ChangePINViewModel] Dismissing OTP modal")
        showOTP = false
        otpReference = nil
        otpCode = ""
        error = nil
    }

    /// Clears the error state
    /// Called when user modifies input to allow retry
    func clearError() {
        error = nil
    }
}
