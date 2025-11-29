// OTPView.swift
// BankingApp
//
// OTP verification screen implementing MVVM pattern for multi-factor authentication.
// Features 6-digit input, countdown timer, resend functionality, and error handling.

import SwiftUI

// MARK: - OTPView

/// OTP verification screen for multi-factor authentication.
///
/// Features:
/// - Purpose-specific header with icon and message
/// - 6-digit OTP input using OTPInputView component
/// - Countdown timer with warning state (red when < 60s)
/// - Verify button with loading state
/// - Resend OTP button (enabled when expired)
/// - Error message display
/// - Cancel button for dismissal
/// - Success state with checkmark animation
///
/// Architecture:
/// - Uses @ObservedObject for ViewModel (created by AuthViewFactory)
/// - Delegates all logic to OTPViewModel
/// - No navigation logic in view - handled by ViewModel callbacks
///
/// iOS 15 Compatibility:
/// - Uses .task modifier for initialization
/// - Uses onChange(of:) for auto-submit on 6 digits
/// - Standard SwiftUI sheet presentation
struct OTPView: View {

    // MARK: - Properties

    /// ViewModel managing OTP state and logic
    @ObservedObject var viewModel: OTPViewModel

    // MARK: - Body

    var body: some View {
        NavigationView {
            ZStack {
                // Main content
                ScrollView {
                    VStack(spacing: 24) {
                        // Purpose Header
                        purposeHeader
                            .padding(.top, 20)

                        // Timer Display
                        timerDisplay
                            .padding(.top, 8)

                        // OTP Input
                        otpInputSection
                            .padding(.top, 16)

                        // Error Message
                        if let error = viewModel.error {
                            errorMessage(error)
                        }

                        // Action Buttons
                        actionButtons
                            .padding(.top, 16)

                        // Help Text
                        helpText
                            .padding(.top, 24)

                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, 24)
                }
                .disabled(viewModel.isLoading)

                // Success Overlay
                if viewModel.isSuccess {
                    successOverlay
                }

                // Loading Overlay
                if viewModel.isLoading && !viewModel.isSuccess {
                    loadingOverlay
                }
            }
            .navigationTitle("Verify Identity")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        viewModel.cancel()
                    }
                    .disabled(viewModel.isLoading)
                }
            }
            .interactiveDismissDisabled(viewModel.isLoading)
        }
        .onChange(of: viewModel.otpCode) { newValue in
            // Auto-submit when 6 digits entered
            if newValue.count == 6 && viewModel.canVerify {
                Task {
                    await viewModel.verifyOTP()
                }
            }
        }
    }

    // MARK: - Purpose Header

    /// Header showing purpose-specific icon and message
    private var purposeHeader: some View {
        VStack(spacing: 16) {
            // Purpose Icon
            Image(systemName: viewModel.purposeIcon)
                .font(.system(size: 56))
                .foregroundColor(.blue)
                .accessibilityHidden(true)

            // Purpose Message
            Text(viewModel.purposeMessage)
                .font(.title2)
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)

            // Description
            Text("A verification code has been sent to your registered device.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .accessibilityElement(children: .combine)
    }

    // MARK: - Timer Display

    /// Countdown timer showing time remaining
    private var timerDisplay: some View {
        VStack(spacing: 4) {
            if viewModel.isExpired {
                // Expired state
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.circle.fill")
                        .foregroundColor(.red)
                    Text("Expired")
                        .font(.title3)
                        .fontWeight(.medium)
                        .foregroundColor(.red)
                }
                .accessibilityLabel("OTP code has expired")
            } else {
                // Timer counting down
                HStack(spacing: 6) {
                    Image(systemName: "clock.fill")
                        .foregroundColor(viewModel.isTimerWarning ? .red : .secondary)

                    Text(viewModel.formattedTimeRemaining)
                        .font(.title3.monospacedDigit())
                        .fontWeight(.medium)
                        .foregroundColor(viewModel.isTimerWarning ? .red : .primary)
                }
                .accessibilityLabel("Time remaining: \(viewModel.formattedTimeRemaining)")

                Text("Time remaining")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }

    // MARK: - OTP Input Section

    /// 6-digit OTP input fields
    private var otpInputSection: some View {
        VStack(spacing: 8) {
            OTPInputView(otp: $viewModel.otpCode)
                .disabled(viewModel.isExpired || viewModel.isLoading)
                .opacity(viewModel.isExpired ? 0.5 : 1.0)

            Text("Enter the 6-digit verification code")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("OTP input, \(viewModel.otpCode.count) of 6 digits entered")
    }

    // MARK: - Error Message

    /// Error message display
    private func errorMessage(_ error: Error) -> some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.red)

            Text(error.localizedDescription)
                .font(.callout)
                .foregroundColor(.red)
                .multilineTextAlignment(.leading)

            Spacer()
        }
        .padding()
        .background(Color.red.opacity(0.1))
        .cornerRadius(10)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Error: \(error.localizedDescription)")
    }

    // MARK: - Action Buttons

    /// Verify and Resend buttons
    private var actionButtons: some View {
        VStack(spacing: 12) {
            // Verify Button
            ActionButton(
                title: "Verify",
                isLoading: viewModel.isLoading,
                isDisabled: !viewModel.canVerify,
                action: {
                    Task {
                        await viewModel.verifyOTP()
                    }
                }
            )
            .accessibilityHint(viewModel.canVerify ? "Double tap to verify OTP code" : "Enter all 6 digits to enable")

            // Resend Button (visible when expired or as secondary action)
            Button {
                Task {
                    await viewModel.resendOTP()
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.clockwise")
                        .font(.body)
                    Text(viewModel.isExpired ? "Request New Code" : "Resend Code")
                        .font(.body.weight(.medium))
                }
                .foregroundColor(viewModel.isExpired ? .blue : .secondary)
            }
            .disabled(viewModel.isLoading)
            .padding(.top, 4)
            .accessibilityLabel(viewModel.isExpired ? "Request new verification code" : "Resend verification code")
        }
    }

    // MARK: - Help Text

    /// Help text at bottom
    private var helpText: some View {
        VStack(spacing: 8) {
            Text("Didn't receive a code?")
                .font(.subheadline)
                .foregroundColor(.secondary)

            Text("Check your SMS messages or try requesting a new code.")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            // Mock code hint (for demo purposes)
            #if DEBUG
            Text("Demo: Use code 123456")
                .font(.caption2)
                .foregroundColor(.orange)
                .padding(.top, 8)
            #endif
        }
    }

    // MARK: - Success Overlay

    /// Success state overlay with checkmark
    private var successOverlay: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 64))
                    .foregroundColor(.green)

                Text("Verified!")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)

                Text("Redirecting...")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
            }
            .padding(32)
            .background(Color(.systemGray5))
            .cornerRadius(20)
        }
        .accessibilityLabel("Verification successful, redirecting")
    }

    // MARK: - Loading Overlay

    /// Loading overlay during verification
    private var loadingOverlay: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                ProgressView()
                    .scaleEffect(1.2)
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))

                Text("Verifying...")
                    .font(.subheadline)
                    .foregroundColor(.white)
            }
            .padding(24)
            .background(Color(.systemGray5))
            .cornerRadius(16)
        }
        .accessibilityLabel("Verifying OTP code, please wait")
    }
}

// MARK: - Preview

#Preview("OTPView - Fresh") {
    let container = DependencyContainer()
    let coordinator = AuthCoordinator(parent: AppCoordinator(dependencyContainer: container), dependencyContainer: container)
    let viewModel = OTPViewModel(
        otpReference: OTPReference(
            id: "OTP-123",
            expiresAt: Date().addingTimeInterval(300),
            purpose: .login
        ),
        authService: container.authService,
        coordinator: coordinator
    )
    return OTPView(viewModel: viewModel)
}

#Preview("OTPView - Expired") {
    let container = DependencyContainer()
    let coordinator = AuthCoordinator(parent: AppCoordinator(dependencyContainer: container), dependencyContainer: container)
    let viewModel = OTPViewModel(
        otpReference: OTPReference(
            id: "OTP-456",
            expiresAt: Date().addingTimeInterval(-60), // Already expired
            purpose: .transfer
        ),
        authService: container.authService,
        coordinator: coordinator
    )
    return OTPView(viewModel: viewModel)
}
