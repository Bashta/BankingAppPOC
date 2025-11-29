// ForgotPasswordViewModel.swift
// Story 2.8: Implement Forgot Password Flow

import Foundation
import SwiftUI
import Combine
import OSLog

/// ViewModel for the forgot password flow
/// Handles email submission, validation, and navigation back to login
///
/// AC: #1 - Required @Published properties
/// AC: #2 - Email validation with isValidEmail computed property
/// AC: #3 - submitForgotPassword async method with proper state management
/// AC: #4 - Navigation method to return to login
final class ForgotPasswordViewModel: ObservableObject {
    // MARK: - Published Properties (AC: #1)

    /// User's email input
    @Published var email: String = ""

    /// Loading state during submission
    @Published var isSubmitting: Bool = false

    /// Error state for failed submissions
    @Published var error: Error?

    /// Success message after successful submission
    @Published var successMessage: String?

    /// Tracks whether the form has been successfully submitted
    @Published var hasSubmitted: Bool = false

    // MARK: - Dependencies (AC: #1)

    private let authService: AuthServiceProtocol
    weak var coordinator: AuthCoordinator?

    // MARK: - Computed Properties (AC: #2)

    /// Validates email format - basic check for "@" and minimum length
    /// Returns true if email format is acceptable
    var isValidEmail: Bool {
        email.contains("@") && email.count >= 5
    }

    // MARK: - Initialization (AC: #1)

    /// Creates a ForgotPasswordViewModel with required dependencies
    /// - Parameters:
    ///   - authService: Service for authentication operations
    ///   - coordinator: AuthCoordinator for navigation (weak reference to prevent retain cycles)
    init(authService: AuthServiceProtocol, coordinator: AuthCoordinator?) {
        self.authService = authService
        self.coordinator = coordinator
    }

    // MARK: - Actions (AC: #3)

    /// Submits the forgot password request to the auth service
    /// Sets loading state, clears previous error, and handles success/failure
    ///
    /// AC: #3 Requirements:
    /// - Sets isSubmitting = true before auth call
    /// - Uses defer to ensure isSubmitting = false after completion
    /// - Clears previous error before attempt
    /// - On success: sets successMessage and hasSubmitted = true
    /// - On error: sets error property
    /// - Includes debug logging
    @MainActor
    func submitForgotPassword() async {
        isSubmitting = true
        error = nil
        defer { isSubmitting = false }

        Logger.auth.debug("[ForgotPasswordViewModel] Submitting forgot password for email: \(self.email.prefix(3))***")

        do {
            try await authService.forgotPassword(email: email)

            successMessage = "Password reset link sent to your email"
            hasSubmitted = true

            Logger.auth.info("[ForgotPasswordViewModel] Reset email sent successfully")

        } catch {
            self.error = error
            Logger.auth.error("[ForgotPasswordViewModel] forgotPassword failed: \(error.localizedDescription)")
        }
    }

    // MARK: - Navigation (AC: #4)

    /// Navigates back to the login screen
    /// Called after success message shown or via back navigation
    func navigateBackToLogin() {
        Logger.auth.debug("[ForgotPasswordViewModel] Navigating back to login")
        coordinator?.pop()
    }

    /// Clears the error state
    /// Called when user modifies input to allow retry
    func clearError() {
        error = nil
    }
}
