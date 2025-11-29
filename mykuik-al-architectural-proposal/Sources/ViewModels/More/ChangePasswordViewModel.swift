// ChangePasswordViewModel.swift
// Story 2.9: Implement Change Password Flow

import Foundation
import SwiftUI
import Combine
import OSLog

/// ViewModel for the change password flow
/// Handles password validation, strength requirements, submission, and navigation
///
/// AC: #1 - Required @Published properties
/// AC: #2 - Password validation computed properties
/// AC: #3 - changePassword async method with proper state management
/// AC: #4 - Navigation methods
final class ChangePasswordViewModel: ObservableObject {
    // MARK: - Published Properties (AC: #1)

    /// User's current password input
    @Published var currentPassword: String = ""

    /// User's new password input
    @Published var newPassword: String = ""

    /// User's confirm password input
    @Published var confirmPassword: String = ""

    /// Loading state during password change
    @Published var isChanging: Bool = false

    /// Error state for failed password change
    @Published var error: Error?

    /// Success message after successful password change
    @Published var successMessage: String?

    /// Tracks whether the password has been successfully changed
    @Published var hasChanged: Bool = false

    // MARK: - Dependencies (AC: #1)

    private let authService: AuthServiceProtocol
    weak var coordinator: MoreCoordinator?

    // MARK: - Validation Computed Properties (AC: #2)

    /// Validates current password is not empty
    var isCurrentPasswordValid: Bool {
        !currentPassword.isEmpty
    }

    /// Password meets minimum length requirement (8+ characters)
    var hasMinLength: Bool {
        newPassword.count >= 8
    }

    /// Password contains at least one uppercase letter
    var hasUppercase: Bool {
        newPassword.contains(where: { $0.isUppercase })
    }

    /// Password contains at least one lowercase letter
    var hasLowercase: Bool {
        newPassword.contains(where: { $0.isLowercase })
    }

    /// Password contains at least one number
    var hasNumber: Bool {
        newPassword.contains(where: { $0.isNumber })
    }

    /// Password contains at least one special character
    var hasSpecialChar: Bool {
        let specialChars = "!@#$%^&*(),.?\":{}|<>"
        return newPassword.contains(where: { specialChars.contains($0) })
    }

    /// New password meets all strength requirements
    var isNewPasswordValid: Bool {
        hasMinLength && hasUppercase && hasLowercase && hasNumber && hasSpecialChar
    }

    /// Confirm password matches new password (and new password is not empty)
    var doPasswordsMatch: Bool {
        !newPassword.isEmpty && newPassword == confirmPassword
    }

    /// New password differs from current password
    var passwordsDiffer: Bool {
        !newPassword.isEmpty && !currentPassword.isEmpty && newPassword != currentPassword
    }

    /// Form is valid when all conditions are met
    var isFormValid: Bool {
        isCurrentPasswordValid && isNewPasswordValid && doPasswordsMatch && passwordsDiffer
    }

    // MARK: - Initialization (AC: #1)

    /// Creates a ChangePasswordViewModel with required dependencies
    /// - Parameters:
    ///   - authService: Service for authentication operations
    ///   - coordinator: MoreCoordinator for navigation (weak reference to prevent retain cycles)
    init(authService: AuthServiceProtocol, coordinator: MoreCoordinator?) {
        self.authService = authService
        self.coordinator = coordinator
    }

    // MARK: - Actions (AC: #3)

    /// Changes the user's password via the auth service
    /// Sets loading state, clears previous error, and handles success/failure
    ///
    /// AC: #3 Requirements:
    /// - Sets isChanging = true before auth call
    /// - Uses defer to ensure isChanging = false after completion
    /// - Clears previous error before attempt
    /// - Validates passwords don't match (new != current)
    /// - Calls authService.changePassword(oldPassword:, newPassword:)
    /// - On success: sets successMessage and hasChanged = true
    /// - On error: sets error property
    /// - Includes debug logging
    @MainActor
    func changePassword() async {
        isChanging = true
        error = nil
        defer { isChanging = false }

        Logger.auth.debug("[ChangePasswordViewModel] Attempting to change password")

        do {
            try await authService.changePassword(oldPassword: currentPassword, newPassword: newPassword)

            successMessage = "Password changed successfully"
            hasChanged = true

            Logger.auth.info("[ChangePasswordViewModel] Password changed successfully")

        } catch {
            self.error = error
            Logger.auth.error("[ChangePasswordViewModel] changePassword failed: \(error.localizedDescription)")
        }
    }

    // MARK: - Navigation (AC: #4)

    /// Navigates back to the previous screen
    /// Called via back navigation or cancel
    func navigateBack() {
        Logger.auth.debug("[ChangePasswordViewModel] Navigating back")
        coordinator?.pop()
    }

    /// Navigates back after successful password change
    /// Called when user taps "Done" on success view
    func dismissAfterSuccess() {
        Logger.auth.debug("[ChangePasswordViewModel] Dismissing after success")
        coordinator?.pop()
    }

    /// Clears the error state
    /// Called when user modifies input to allow retry
    func clearError() {
        error = nil
    }
}
