// ForgotPasswordView.swift
// Story 2.8: Implement Forgot Password Flow
//
// Forgot password screen for requesting password reset.
// Users enter their email address and receive a reset link.

import SwiftUI

// MARK: - ForgotPasswordView

/// Forgot password screen for the banking app.
///
/// Features:
/// - Instruction text explaining the feature
/// - Email input field with validation
/// - Submit button with loading state
/// - Success state with checkmark and return button
/// - Error message display
/// - Back to login navigation
///
/// Architecture:
/// - Uses @ObservedObject for ViewModel (created by AuthViewFactory)
/// - Delegates all logic to ForgotPasswordViewModel
/// - No navigation logic in view - handled by coordinator via ViewModel
///
/// AC: #5 - Renders forgot password UI
/// AC: #6 - Implements UI states (loading, error, success)
/// AC: #7 - Handles success flow with checkmark and return button
struct ForgotPasswordView: View {

    // MARK: - Properties

    /// ViewModel managing forgot password state and logic
    @ObservedObject var viewModel: ForgotPasswordViewModel

    // MARK: - Body

    var body: some View {
        ZStack {
            // Main content
            ScrollView {
                VStack(spacing: 24) {
                    // Icon
                    iconSection
                        .padding(.top, 40)

                    // Instruction text (AC: #5)
                    instructionText

                    if viewModel.hasSubmitted {
                        // Success State (AC: #7)
                        successView
                    } else {
                        // Form State (AC: #5, #6)
                        formView
                    }

                    Spacer(minLength: 40)
                }
            }
            .disabled(viewModel.isSubmitting)

            // Loading Overlay (AC: #6)
            if viewModel.isSubmitting {
                loadingOverlay
            }
        }
        .navigationTitle("Forgot Password")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: viewModel.email) { _ in
            // Clear error when user types
            viewModel.clearError()
        }
    }

    // MARK: - Icon Section

    /// Icon at the top of the screen
    private var iconSection: some View {
        Image(systemName: viewModel.hasSubmitted ? "checkmark.circle.fill" : "envelope.badge.shield.half.filled")
            .font(.system(size: 60))
            .foregroundColor(viewModel.hasSubmitted ? .green : .blue)
            .accessibilityHidden(true)
    }

    // MARK: - Instruction Text (AC: #5)

    /// Instruction text explaining the feature
    private var instructionText: some View {
        Text(viewModel.hasSubmitted
             ? "Check your inbox and follow the instructions to reset your password."
             : "Enter your registered email address and we'll send you a reset link.")
            .font(.body)
            .multilineTextAlignment(.center)
            .foregroundColor(.secondary)
            .padding(.horizontal, 32)
    }

    // MARK: - Form View (AC: #5, #6)

    /// Form with email input and submit button
    private var formView: some View {
        VStack(spacing: 16) {
            // Email TextField (AC: #5)
            emailField

            // Error message (AC: #6)
            if let error = viewModel.error {
                errorMessage(error)
            }

            // Submit button (AC: #5)
            submitButton
                .padding(.top, 8)

            // Back to login link (AC: #5)
            backToLoginButton
                .padding(.top, 8)
        }
        .padding(.horizontal, 32)
    }

    // MARK: - Email Field (AC: #5)

    /// Email text field with proper keyboard and autocapitalization settings
    private var emailField: some View {
        TextField("Email", text: $viewModel.email)
            .textContentType(.emailAddress)
            .autocapitalization(.none)
            .disableAutocorrection(true)
            .keyboardType(.emailAddress)
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(10)
            .disabled(viewModel.isSubmitting)
            .accessibilityLabel("Email address")
            .accessibilityHint("Enter your registered email address")
    }

    // MARK: - Error Message (AC: #6)

    /// Displays error message in red text below form
    private func errorMessage(_ error: Error) -> some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.red)

            Text(error.localizedDescription)
                .font(.caption)
                .foregroundColor(.red)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Error: \(error.localizedDescription)")
    }

    // MARK: - Submit Button (AC: #5)

    /// Submit button that triggers forgot password request
    private var submitButton: some View {
        ActionButton(
            title: "Send Reset Link",
            isLoading: viewModel.isSubmitting,
            isDisabled: !viewModel.isValidEmail
        ) {
            Task {
                await viewModel.submitForgotPassword()
            }
        }
        .accessibilityHint(viewModel.isValidEmail
                           ? "Double tap to send password reset link"
                           : "Enter a valid email address first")
    }

    // MARK: - Back to Login Button (AC: #5)

    /// Back to login navigation link
    private var backToLoginButton: some View {
        Button {
            viewModel.navigateBackToLogin()
        } label: {
            Text("Back to Login")
                .font(.subheadline)
                .foregroundColor(.blue)
        }
        .disabled(viewModel.isSubmitting)
        .accessibilityLabel("Back to Login")
        .accessibilityHint("Double tap to return to login screen")
    }

    // MARK: - Success View (AC: #7)

    /// Success state showing checkmark and return button
    private var successView: some View {
        VStack(spacing: 24) {
            // Success message (AC: #7)
            if let message = viewModel.successMessage {
                Text(message)
                    .font(.headline)
                    .foregroundColor(.green)
                    .multilineTextAlignment(.center)
                    .accessibilityLabel(message)
            }

            // Return to login button (AC: #7)
            Button {
                viewModel.navigateBackToLogin()
            } label: {
                Text("Return to Login")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
            }
            .buttonStyle(.borderedProminent)
            .padding(.horizontal, 32)
            .accessibilityLabel("Return to Login")
            .accessibilityHint("Double tap to return to login screen")
        }
    }

    // MARK: - Loading Overlay (AC: #6)

    /// Loading overlay shown during submission
    private var loadingOverlay: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                ProgressView()
                    .scaleEffect(1.2)
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))

                Text("Sending...")
                    .font(.subheadline)
                    .foregroundColor(.white)
            }
            .padding(24)
            .background(Color(.systemGray5))
            .cornerRadius(16)
        }
        .accessibilityLabel("Sending password reset link, please wait")
    }
}

// MARK: - Preview

#Preview("ForgotPasswordView - Form State") {
    NavigationView {
        ForgotPasswordView(
            viewModel: ForgotPasswordViewModel(
                authService: MockAuthService(),
                coordinator: nil
            )
        )
    }
}

#Preview("ForgotPasswordView - Success State") {
    NavigationView {
        let viewModel = ForgotPasswordViewModel(
            authService: MockAuthService(),
            coordinator: nil
        )
        ForgotPasswordView(viewModel: viewModel)
            .onAppear {
                viewModel.hasSubmitted = true
                viewModel.successMessage = "Password reset link sent to your email"
            }
    }
}
