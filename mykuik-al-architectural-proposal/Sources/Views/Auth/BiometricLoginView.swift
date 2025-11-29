// BiometricLoginView.swift
// BankingApp
//
// Standalone biometric authentication screen implementing MVVM pattern.
// Used for quick re-authentication scenarios like session timeout.

import SwiftUI

// MARK: - BiometricLoginView

/// Standalone view for biometric (Face ID / Touch ID) authentication.
///
/// Use Cases:
/// - Quick re-authentication after session timeout
/// - Deep link to biometric login
/// - Direct biometric auth flow without username/password
///
/// Features:
/// - Auto-triggers biometric prompt on appear (optional)
/// - Manual retry button
/// - Error display with user-friendly messages
/// - Password fallback option
/// - OTP modal if required
/// - Loading state during authentication
///
/// Architecture:
/// - Uses @ObservedObject for ViewModel (created by AuthViewFactory)
/// - Delegates all logic to BiometricLoginViewModel
/// - Coordinator handles navigation after success/fallback
///
/// iOS 15 Compatibility:
/// - Uses .task modifier for biometric availability check
/// - Standard SwiftUI components (no iOS 16+ APIs)
struct BiometricLoginView: View {

    // MARK: - Properties

    /// ViewModel managing biometric login state and logic
    @ObservedObject var viewModel: BiometricLoginViewModel

    /// Whether to auto-trigger biometric on appear
    private let autoTrigger: Bool = true

    // MARK: - Body

    var body: some View {
        ZStack {
            // Main content
            ScrollView {
                VStack(spacing: 32) {
                    Spacer(minLength: 40)

                    // Biometric Icon
                    biometricIconView
                        .padding(.top, 60)

                    // Title and Description
                    headerSection

                    // Error Display
                    if let error = viewModel.error {
                        errorSection(error)
                    }

                    // Actions
                    actionSection
                        .padding(.horizontal, 32)

                    Spacer(minLength: 40)
                }
            }
            .disabled(viewModel.isAuthenticating)

            // Loading Overlay
            if viewModel.isAuthenticating {
                loadingOverlay
            }
        }
        .navigationTitle("Login")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            // Check biometric availability on appear
            viewModel.checkBiometricAvailability()

            // Auto-trigger biometric prompt if enabled
            if autoTrigger && viewModel.canUseBiometrics {
                // Small delay to let view settle
                try? await Task.sleep(nanoseconds: 300_000_000)
                await viewModel.authenticateWithBiometric()
            }
        }
        .sheet(isPresented: $viewModel.showOTP) {
            // OTP modal for multi-factor authentication
            otpModalContent
        }
    }

    // MARK: - Biometric Icon

    private var biometricIconView: some View {
        VStack(spacing: 16) {
            // Large biometric icon
            Image(systemName: viewModel.biometricIcon)
                .font(.system(size: 80))
                .foregroundColor(iconColor)
                .accessibilityHidden(true)

            // Icon loading animation
            if viewModel.isAuthenticating {
                ProgressView()
                    .scaleEffect(0.8)
            }
        }
        .frame(width: 120, height: 120)
        .background(
            Circle()
                .fill(Color(.systemGray6))
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(viewModel.biometricTypeName) icon")
    }

    private var iconColor: Color {
        if viewModel.error != nil {
            return .red
        } else if viewModel.isAuthenticating {
            return .blue.opacity(0.6)
        } else {
            return .blue
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: 12) {
            Text("Welcome Back")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.primary)

            if viewModel.canUseBiometrics {
                Text("Use \(viewModel.biometricTypeName) to sign in")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            } else {
                Text("Biometric authentication is not available")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.horizontal, 32)
        .accessibilityElement(children: .combine)
    }

    // MARK: - Error Section

    private func errorSection(_ error: BiometricError) -> some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "exclamationmark.circle.fill")
                    .foregroundColor(.red)

                Text(error.userFriendlyMessage)
                    .font(.subheadline)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.leading)

                Spacer()
            }
            .padding()
            .background(Color.red.opacity(0.1))
            .cornerRadius(10)
        }
        .padding(.horizontal, 32)
        .transition(.opacity)
        .animation(.easeInOut, value: viewModel.error != nil)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Error: \(error.userFriendlyMessage)")
    }

    // MARK: - Action Section

    private var actionSection: some View {
        VStack(spacing: 16) {
            if viewModel.canUseBiometrics {
                // Retry biometric button
                biometricRetryButton
            }

            // Password fallback (always available when there's an error or biometrics unavailable)
            if viewModel.showPasswordFallback || !viewModel.canUseBiometrics || viewModel.error != nil {
                passwordFallbackButton
            }
        }
    }

    private var biometricRetryButton: some View {
        Button {
            viewModel.retryBiometric()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: viewModel.biometricIcon)
                    .font(.title3)

                Text("Use \(viewModel.biometricTypeName)")
                    .font(.body)
                    .fontWeight(.medium)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .foregroundColor(.white)
            .background(Color.blue)
            .cornerRadius(10)
        }
        .disabled(viewModel.isAuthenticating)
        .opacity(viewModel.isAuthenticating ? 0.6 : 1.0)
        .accessibilityLabel("Authenticate with \(viewModel.biometricTypeName)")
        .accessibilityHint("Double tap to start biometric authentication")
    }

    private var passwordFallbackButton: some View {
        Button {
            viewModel.fallbackToPassword()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "key.fill")
                    .font(.title3)

                Text("Use Password")
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
        .disabled(viewModel.isAuthenticating)
        .opacity(viewModel.isAuthenticating ? 0.6 : 1.0)
        .accessibilityLabel("Use password to log in")
        .accessibilityHint("Double tap to go to password login")
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

                Text("Authenticating...")
                    .font(.subheadline)
                    .foregroundColor(.white)
            }
            .padding(24)
            .background(Color(.systemGray5))
            .cornerRadius(16)
        }
        .accessibilityLabel("Authenticating with \(viewModel.biometricTypeName), please wait")
    }

    // MARK: - OTP Modal Content

    @ViewBuilder
    private var otpModalContent: some View {
        NavigationView {
            VStack(spacing: 24) {
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)
                    .padding(.top, 40)

                Text("Verification Required")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("A verification code has been sent to your registered device. Please enter it to complete login.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)

                // OTP Reference info
                if let otpRef = viewModel.currentOTPReference {
                    Text("Reference: \(otpRef.id)")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text("Expires: \(otpRef.expiresAt, style: .relative)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                // Cancel button to dismiss modal
                Button("Cancel") {
                    viewModel.showOTP = false
                }
                .foregroundColor(.red)
                .padding(.bottom, 32)
            }
            .navigationTitle("Verify Identity")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        viewModel.showOTP = false
                    }
                }
            }
        }
    }
}
