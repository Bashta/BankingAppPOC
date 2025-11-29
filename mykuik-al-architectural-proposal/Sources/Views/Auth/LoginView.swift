// LoginView.swift
// BankingApp
//
// Login screen implementing MVVM pattern for username/password authentication.
// Supports biometric login (Face ID / Touch ID) and OTP multi-factor authentication.

import SwiftUI

// MARK: - LoginView

/// Main login screen for the banking app.
///
/// Features:
/// - App branding (logo/title)
/// - Username/password form fields
/// - Login button with loading state
/// - Biometric login button (conditional)
/// - Forgot password link
/// - Error message display
/// - OTP modal presentation for MFA
///
/// Architecture:
/// - Uses @ObservedObject for ViewModel (created by AuthViewFactory)
/// - Delegates all logic to LoginViewModel
/// - No navigation logic in view - handled by coordinator via ViewModel
///
/// iOS 15 Compatibility:
/// - Uses .task modifier for biometric availability check
/// - Uses onChange(of:) for error clearing
/// - No NavigationStack (iOS 16+)
struct LoginView: View {

    // MARK: - Properties

    /// ViewModel managing login state and logic
    @ObservedObject var viewModel: LoginViewModel

    // MARK: - Body

    var body: some View {
        ZStack {
            // Main content
            ScrollView {
                VStack(spacing: 24) {
                    // Logo and App Title
                    brandingSection
                        .padding(.top, 60)
                        .padding(.bottom, 40)

                    // Login Form
                    formSection
                        .padding(.horizontal, 32)

                    Spacer(minLength: 40)
                }
            }
            .disabled(viewModel.isLoading)

            // Loading Overlay
            if viewModel.isLoading {
                loadingOverlay
            }
        }
        .navigationTitle("Login")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarHidden(true)
        .task {
            // Check biometric availability on view appear
            viewModel.checkBiometricAvailability()
        }
        .onChange(of: viewModel.username) { _ in
            // Clear error when user types
            viewModel.clearError()
        }
        .onChange(of: viewModel.password) { _ in
            // Clear error when user types
            viewModel.clearError()
        }
        .sheet(isPresented: $viewModel.showOTP) {
            // OTP modal for multi-factor authentication
            otpModalContent
        }
    }

    // MARK: - Branding Section

    /// App logo and title at top of screen
    private var brandingSection: some View {
        VStack(spacing: 12) {
            // App Logo
            Image(systemName: "building.columns.fill")
                .font(.system(size: 64))
                .foregroundColor(.blue)
                .accessibilityHidden(true)

            // App Title
            Text("Banking App")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.primary)

            // Tagline
            Text("Secure. Simple. Smart.")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Banking App, Secure Simple Smart")
    }

    // MARK: - Form Section

    /// Login form with username, password, buttons
    private var formSection: some View {
        VStack(spacing: 16) {
            // Username Field
            usernameField

            // Password Field
            passwordField

            // Error Message
            if let error = viewModel.error {
                errorMessage(error)
            }

            // Login Button
            loginButton
                .padding(.top, 8)

            // Biometric Login Button (conditional)
            if viewModel.canUseBiometrics {
                biometricButton
            }

            // Forgot Password Link
            forgotPasswordButton
                .padding(.top, 8)
        }
    }

    // MARK: - Username Field

    private var usernameField: some View {
        TextField("Username", text: $viewModel.username)
            .textContentType(.username)
            .autocapitalization(.none)
            .disableAutocorrection(true)
            .keyboardType(.emailAddress)
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(10)
            .accessibilityLabel("Username")
            .accessibilityHint("Enter your username or email")
    }

    // MARK: - Password Field

    private var passwordField: some View {
        SecureField("Password", text: $viewModel.password)
            .textContentType(.password)
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(10)
            .accessibilityLabel("Password")
            .accessibilityHint("Enter your password")
    }

    // MARK: - Error Message

    private func errorMessage(_ error: Error) -> some View {
        HStack {
            Image(systemName: "exclamationmark.circle.fill")
                .foregroundColor(.red)

            Text(error.localizedDescription)
                .font(.caption)
                .foregroundColor(.red)
                .multilineTextAlignment(.leading)

            Spacer()
        }
        .padding(.horizontal, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Error: \(error.localizedDescription)")
    }

    // MARK: - Login Button

    private var loginButton: some View {
        ActionButton(
            title: "Login",
            isLoading: viewModel.isLoading,
            isDisabled: !viewModel.isValid,
            action: {
                Task {
                    await viewModel.login()
                }
            }
        )
        .accessibilityHint(viewModel.isValid ? "Double tap to login" : "Enter username and password to enable")
    }

    // MARK: - Biometric Button

    private var biometricButton: some View {
        Button {
            Task {
                await viewModel.loginWithBiometric()
            }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: biometricIcon)
                    .font(.title3)

                Text("Login with \(biometricTitle)")
                    .font(.body)
                    .fontWeight(.medium)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .foregroundColor(.blue)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.blue, lineWidth: 2)
            )
        }
        .disabled(viewModel.isLoading)
        .opacity(viewModel.isLoading ? 0.6 : 1.0)
        .accessibilityLabel("Login with \(biometricTitle)")
        .accessibilityHint("Double tap to authenticate with \(biometricTitle)")
    }

    /// SF Symbol name for current biometric type
    private var biometricIcon: String {
        switch viewModel.biometricType {
        case .faceID:
            return "faceid"
        case .touchID:
            return "touchid"
        case .none:
            return ""
        }
    }

    /// Display name for current biometric type
    private var biometricTitle: String {
        switch viewModel.biometricType {
        case .faceID:
            return "Face ID"
        case .touchID:
            return "Touch ID"
        case .none:
            return ""
        }
    }

    // MARK: - Forgot Password Button

    private var forgotPasswordButton: some View {
        Button {
            viewModel.navigateToForgotPassword()
        } label: {
            Text("Forgot password?")
                .font(.subheadline)
                .foregroundColor(.blue)
        }
        .disabled(viewModel.isLoading)
        .accessibilityLabel("Forgot password")
        .accessibilityHint("Double tap to reset your password")
    }

    // MARK: - Loading Overlay

    private var loadingOverlay: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                ProgressView()
                    .scaleEffect(1.2)
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))

                Text("Signing in...")
                    .font(.subheadline)
                    .foregroundColor(.white)
            }
            .padding(24)
            .background(Color(.systemGray5))
            .cornerRadius(16)
        }
        .accessibilityLabel("Signing in, please wait")
    }

    // MARK: - OTP Modal Content

    @ViewBuilder
    private var otpModalContent: some View {
        // Create OTPViewModel with dismiss callback wired up
        if let coordinator = viewModel.coordinator,
           let otpViewModel = viewModel.createOTPViewModel(coordinator: coordinator) {
            OTPView(viewModel: otpViewModel)
        } else {
            // Fallback if coordinator or OTP reference is not available
            fallbackOTPContent
        }
    }

    /// Fallback content when OTPViewModel cannot be created
    private var fallbackOTPContent: some View {
        NavigationView {
            VStack(spacing: 24) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.orange)
                    .padding(.top, 40)

                Text("Verification Required")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("Unable to load verification screen. Please try again.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)

                Spacer()

                Button("Close") {
                    viewModel.showOTP = false
                }
                .foregroundColor(.red)
                .padding(.bottom, 32)
            }
            .navigationTitle("Error")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        viewModel.showOTP = false
                    }
                }
            }
        }
    }
}
