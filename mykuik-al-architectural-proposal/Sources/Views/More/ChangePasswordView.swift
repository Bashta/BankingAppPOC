// ChangePasswordView.swift
// Story 2.9: Implement Change Password Flow
//
// Change password screen for authenticated users.
// Users enter current password and new password with strength validation.

import SwiftUI

// MARK: - ChangePasswordView

/// Change password screen for the banking app.
///
/// Features:
/// - Current password field with show/hide toggle
/// - New password field with show/hide toggle
/// - Confirm password field with show/hide toggle
/// - Password requirements checklist with real-time validation
/// - Submit button with loading state
/// - Success state with checkmark and Done button
/// - Error message display
///
/// Architecture:
/// - Uses @ObservedObject for ViewModel (created by MoreViewFactory)
/// - Delegates all logic to ChangePasswordViewModel
/// - No navigation logic in view - handled by coordinator via ViewModel
///
/// AC: #5 - Renders password change UI
/// AC: #6 - Displays password requirements checklist
/// AC: #7 - Implements UI states (loading, error, success)
struct ChangePasswordView: View {

    // MARK: - Properties

    /// ViewModel managing change password state and logic
    @ObservedObject var viewModel: ChangePasswordViewModel

    /// State for password visibility toggles
    @State private var showCurrentPassword = false
    @State private var showNewPassword = false
    @State private var showConfirmPassword = false

    // MARK: - Body

    var body: some View {
        ZStack {
            // Main content
            ScrollView {
                VStack(spacing: 24) {
                    if viewModel.hasChanged {
                        // Success State (AC: #7)
                        successView
                            .padding(.top, 60)
                    } else {
                        // Form State (AC: #5, #6)
                        formView
                            .padding(.top, 24)
                    }

                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 20)
            }
            .disabled(viewModel.isChanging)

            // Loading Overlay (AC: #7)
            if viewModel.isChanging {
                loadingOverlay
            }
        }
        .navigationTitle("Change Password")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: viewModel.currentPassword) { _ in
            viewModel.clearError()
        }
        .onChange(of: viewModel.newPassword) { _ in
            viewModel.clearError()
        }
        .onChange(of: viewModel.confirmPassword) { _ in
            viewModel.clearError()
        }
    }

    // MARK: - Form View (AC: #5)

    /// Form with password inputs and requirements checklist
    private var formView: some View {
        VStack(spacing: 20) {
            // Current Password Field (AC: #5)
            currentPasswordField

            // New Password Field (AC: #5)
            newPasswordField

            // Confirm Password Field (AC: #5)
            confirmPasswordField

            // Requirements Checklist (AC: #6)
            requirementsChecklist

            // Error message (AC: #7)
            if let error = viewModel.error {
                errorMessage(error)
            }

            // Change Password Button (AC: #5)
            changePasswordButton
                .padding(.top, 8)
        }
    }

    // MARK: - Current Password Field (AC: #5)

    /// Current password input with show/hide toggle
    private var currentPasswordField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Current Password")
                .font(.subheadline)
                .foregroundColor(.secondary)

            HStack {
                if showCurrentPassword {
                    TextField("Enter current password", text: $viewModel.currentPassword)
                        .textContentType(.password)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                } else {
                    SecureField("Enter current password", text: $viewModel.currentPassword)
                        .textContentType(.password)
                }

                Button {
                    showCurrentPassword.toggle()
                } label: {
                    Image(systemName: showCurrentPassword ? "eye.slash" : "eye")
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(10)
            .disabled(viewModel.isChanging)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Current password field")
    }

    // MARK: - New Password Field (AC: #5)

    /// New password input with show/hide toggle
    private var newPasswordField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("New Password")
                .font(.subheadline)
                .foregroundColor(.secondary)

            HStack {
                if showNewPassword {
                    TextField("Enter new password", text: $viewModel.newPassword)
                        .textContentType(.newPassword)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                } else {
                    SecureField("Enter new password", text: $viewModel.newPassword)
                        .textContentType(.newPassword)
                }

                Button {
                    showNewPassword.toggle()
                } label: {
                    Image(systemName: showNewPassword ? "eye.slash" : "eye")
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(10)
            .disabled(viewModel.isChanging)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("New password field")
    }

    // MARK: - Confirm Password Field (AC: #5)

    /// Confirm password input with show/hide toggle
    private var confirmPasswordField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Confirm New Password")
                .font(.subheadline)
                .foregroundColor(.secondary)

            HStack {
                if showConfirmPassword {
                    TextField("Confirm new password", text: $viewModel.confirmPassword)
                        .textContentType(.newPassword)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                } else {
                    SecureField("Confirm new password", text: $viewModel.confirmPassword)
                        .textContentType(.newPassword)
                }

                Button {
                    showConfirmPassword.toggle()
                } label: {
                    Image(systemName: showConfirmPassword ? "eye.slash" : "eye")
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(10)
            .disabled(viewModel.isChanging)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Confirm password field")
    }

    // MARK: - Requirements Checklist (AC: #6)

    /// Password requirements checklist with visual indicators
    private var requirementsChecklist: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Password Requirements")
                .font(.subheadline)
                .fontWeight(.semibold)

            requirementRow("At least 8 characters", met: viewModel.hasMinLength)
            requirementRow("At least 1 uppercase letter", met: viewModel.hasUppercase)
            requirementRow("At least 1 lowercase letter", met: viewModel.hasLowercase)
            requirementRow("At least 1 number", met: viewModel.hasNumber)
            requirementRow("At least 1 special character", met: viewModel.hasSpecialChar)
            requirementRow("Passwords match", met: viewModel.doPasswordsMatch)
            requirementRow("Different from current password", met: viewModel.passwordsDiffer)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }

    /// Individual requirement row with checkmark indicator
    /// - Parameters:
    ///   - text: Requirement description
    ///   - met: Whether the requirement is satisfied
    private func requirementRow(_ text: String, met: Bool) -> some View {
        HStack(spacing: 8) {
            Image(systemName: met ? "checkmark.circle.fill" : "circle")
                .foregroundColor(met ? .green : .gray)
                .font(.body)
            Text(text)
                .font(.caption)
                .foregroundColor(met ? .primary : .secondary)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(text): \(met ? "met" : "not met")")
    }

    // MARK: - Error Message (AC: #7)

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

    // MARK: - Change Password Button (AC: #5)

    /// Submit button that triggers password change request
    private var changePasswordButton: some View {
        ActionButton(
            title: "Change Password",
            isLoading: viewModel.isChanging,
            isDisabled: !viewModel.isFormValid
        ) {
            Task {
                await viewModel.changePassword()
            }
        }
        .accessibilityHint(viewModel.isFormValid
                           ? "Double tap to change your password"
                           : "Complete all password requirements first")
    }

    // MARK: - Success View (AC: #7)

    /// Success state showing checkmark and Done button
    private var successView: some View {
        VStack(spacing: 24) {
            Spacer()

            // Checkmark icon
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.green)
                .accessibilityHidden(true)

            // Title
            Text("Password Changed")
                .font(.title2)
                .fontWeight(.bold)

            // Success message
            if let message = viewModel.successMessage {
                Text(message)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .accessibilityLabel(message)
            }

            Spacer()

            // Done button
            Button {
                viewModel.dismissAfterSuccess()
            } label: {
                Text("Done")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
            }
            .buttonStyle(.borderedProminent)
            .accessibilityLabel("Done")
            .accessibilityHint("Double tap to return to security settings")
        }
        .padding(.horizontal)
    }

    // MARK: - Loading Overlay (AC: #7)

    /// Loading overlay shown during password change
    private var loadingOverlay: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                ProgressView()
                    .scaleEffect(1.2)
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))

                Text("Changing password...")
                    .font(.subheadline)
                    .foregroundColor(.white)
            }
            .padding(24)
            .background(Color(.systemGray5))
            .cornerRadius(16)
        }
        .accessibilityLabel("Changing password, please wait")
    }
}
