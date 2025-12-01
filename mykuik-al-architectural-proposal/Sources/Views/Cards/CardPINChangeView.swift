//
//  CardPINChangeView.swift
//  BankingApp
//
//  View for Card PIN Change Flow with OTP verification.
//  Features instructions, OTP request, verification modal, and success state.
//  Story 5.6: Implement PIN Change Flow with OTP
//

import SwiftUI

struct CardPINChangeView: View {
    @ObservedObject var viewModel: CardPINChangeViewModel
    @State private var otpCode: String = ""

    var body: some View {
        Group {
            if viewModel.isSuccess {
                successView
            } else {
                mainContent
            }
        }
        .navigationTitle("Change Card PIN")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $viewModel.showOTP) {
            otpModalView
        }
        .onAppear {
            // Reset state when view appears to ensure fresh flow
            viewModel.resetState()
            otpCode = ""
        }
    }

    // MARK: - Main Content

    private var mainContent: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Instructions Section
                instructionsSection
                    .padding(.top, 20)

                // Card Identifier Section
                cardIdentifierSection

                // Error Display
                if let error = viewModel.error {
                    errorSection(error: error)
                }

                Spacer(minLength: 40)

                // Action Buttons
                actionButtonsSection
            }
            .padding(24)
        }
    }

    // MARK: - Instructions Section

    private var instructionsSection: some View {
        VStack(spacing: 16) {
            // Icon
            Image(systemName: "lock.rotation")
                .font(.system(size: 56))
                .foregroundColor(.blue)
                .accessibilityHidden(true)

            // Title
            Text("Secure PIN Change")
                .font(.title2)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)

            // Description
            Text("For your security, we'll send a one-time code to verify this change. Your new PIN will be sent to your registered address.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
        }
        .padding(.horizontal, 8)
    }

    // MARK: - Card Identifier Section

    private var cardIdentifierSection: some View {
        HStack(spacing: 12) {
            Image(systemName: "creditcard.fill")
                .font(.title2)
                .foregroundColor(.blue)

            VStack(alignment: .leading, spacing: 2) {
                Text("Card")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Text("**** **** **** \(String(viewModel.cardId.suffix(4)))")
                    .font(.body.monospacedDigit())
                    .fontWeight(.medium)
            }

            Spacer()
        }
        .padding(16)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }

    // MARK: - Error Section

    private func errorSection(error: Error) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.circle.fill")
                .foregroundColor(.red)

            Text(errorMessage(for: error))
                .font(.subheadline)
                .foregroundColor(.red)
                .multilineTextAlignment(.leading)

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.red.opacity(0.1))
        .cornerRadius(8)
    }

    private func errorMessage(for error: Error) -> String {
        if let cardError = error as? CardError {
            switch cardError {
            case .cardNotFound:
                return "Card not found. Please try again."
            case .invalidOTP:
                return "Invalid verification code. Please try again."
            default:
                return cardError.localizedDescription
            }
        }
        return error.localizedDescription
    }

    // MARK: - Action Buttons Section

    private var actionButtonsSection: some View {
        VStack(spacing: 12) {
            ActionButton(
                title: "Request PIN Change",
                isLoading: viewModel.isRequestingOTP,
                isDisabled: viewModel.isLoading
            ) {
                Task {
                    await viewModel.requestPINChange()
                }
            }

            Button(action: {
                viewModel.cancel()
            }) {
                Text("Cancel")
                    .font(.headline)
                    .foregroundColor(.secondary)
                    .frame(height: 50)
                    .frame(maxWidth: .infinity)
            }
            .disabled(viewModel.isLoading)
        }
    }

    // MARK: - Success View

    private var successView: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.green)

            Text("PIN Change Requested")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.green)

            Text("Your new PIN will be sent to your registered address within 3-5 business days.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Text("Redirecting...")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding(.top, 8)

            Spacer()
        }
        .padding(24)
    }

    // MARK: - OTP Modal View

    private var otpModalView: some View {
        NavigationView {
            ZStack {
                ScrollView {
                    VStack(spacing: 24) {
                        // Purpose Header
                        otpPurposeHeader
                            .padding(.top, 20)

                        // OTP Input
                        otpInputSection
                            .padding(.top, 16)

                        // Error Message
                        if let error = viewModel.error, !viewModel.isSuccess {
                            errorSection(error: error)
                        }

                        // Demo hint
                        #if DEBUG
                        Text("Demo: Use code 123456")
                            .font(.caption2)
                            .foregroundColor(.orange)
                            .padding(.top, 8)
                        #endif

                        // Action Buttons
                        otpActionButtons
                            .padding(.top, 16)

                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, 24)
                }
                .disabled(viewModel.isVerifying)

                // Loading Overlay
                if viewModel.isVerifying {
                    loadingOverlay
                }
            }
            .navigationTitle("Verify Identity")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        otpCode = ""
                        viewModel.dismissOTP()
                    }
                    .disabled(viewModel.isVerifying)
                }
            }
            .interactiveDismissDisabled(viewModel.isVerifying)
        }
        .onChange(of: otpCode) { newValue in
            // Auto-submit when 6 digits entered
            if newValue.count == 6 && !viewModel.isVerifying {
                Task {
                    await viewModel.verifyAndChangePIN(otpCode: otpCode)
                }
            }
        }
    }

    // MARK: - OTP Purpose Header

    private var otpPurposeHeader: some View {
        VStack(spacing: 16) {
            Image(systemName: "lock.rotation")
                .font(.system(size: 56))
                .foregroundColor(.blue)
                .accessibilityHidden(true)

            Text("Verify PIN Change")
                .font(.title2)
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)

            Text("A verification code has been sent to your registered device.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    // MARK: - OTP Input Section

    private var otpInputSection: some View {
        VStack(spacing: 8) {
            OTPInputView(otp: $otpCode)
                .disabled(viewModel.isVerifying)

            Text("Enter the 6-digit verification code")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    // MARK: - OTP Action Buttons

    private var otpActionButtons: some View {
        VStack(spacing: 12) {
            ActionButton(
                title: "Verify",
                isLoading: viewModel.isVerifying,
                isDisabled: otpCode.count != 6
            ) {
                Task {
                    await viewModel.verifyAndChangePIN(otpCode: otpCode)
                }
            }
        }
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

#if DEBUG
struct CardPINChangeView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            CardPINChangeView(
                viewModel: CardPINChangeViewModel(
                    cardId: "CARD001",
                    cardService: MockCardService(),
                    coordinator: CardsCoordinator(
                        parent: AppCoordinator(dependencyContainer: DependencyContainer()),
                        dependencyContainer: DependencyContainer()
                    )
                )
            )
        }
    }
}
#endif
