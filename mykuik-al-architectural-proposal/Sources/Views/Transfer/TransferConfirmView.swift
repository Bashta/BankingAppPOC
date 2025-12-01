import SwiftUI

struct TransferConfirmView: View {
    @ObservedObject var viewModel: TransferConfirmViewModel

    var body: some View {
        ZStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Summary Card
                    TransferSummaryCard(
                        request: viewModel.transferRequest,
                        sourceAccount: viewModel.sourceAccount,
                        destinationAccount: viewModel.destinationAccount,
                        beneficiary: viewModel.beneficiary
                    )

                    // Review Message
                    Text("Please review the details carefully")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)

                    // Error Display
                    if let error = viewModel.error {
                        errorView(error: error)
                    }

                    Spacer(minLength: 40)

                    // Action Buttons
                    actionButtons
                }
                .padding()
            }

            // Loading Overlay
            if viewModel.isSubmitting && !viewModel.showOTP {
                loadingOverlay
            }
        }
        .navigationTitle("Confirm Transfer")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.loadDisplayData()
        }
        .sheet(isPresented: $viewModel.showOTP) {
            TransferOTPSheet(viewModel: viewModel)
        }
    }

    // MARK: - Subviews

    private var actionButtons: some View {
        VStack(spacing: 12) {
            ActionButton(
                title: "Confirm Transfer",
                isLoading: viewModel.isSubmitting,
                isDisabled: viewModel.isLoadingDisplayData,
                action: {
                    Task { await viewModel.initiateTransfer() }
                }
            )

            Button("Edit Transfer") {
                viewModel.cancelTransfer()
            }
            .font(.body)
            .foregroundColor(.accentColor)
            .padding(.vertical, 8)
        }
        .padding(.horizontal)
    }

    private func errorView(error: Error) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.red)

            Text(error.localizedDescription)
                .font(.caption)
                .foregroundColor(.red)
                .multilineTextAlignment(.leading)

            Spacer()

            Button(action: { viewModel.clearError() }) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color.red.opacity(0.1))
        .cornerRadius(8)
    }

    private var loadingOverlay: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                ProgressView()
                    .scaleEffect(1.5)
                    .tint(.white)

                Text("Processing...")
                    .font(.subheadline)
                    .foregroundColor(.white)
            }
            .padding(24)
            .background(Color(.systemBackground).opacity(0.9))
            .cornerRadius(16)
        }
    }
}

// MARK: - OTP Sheet for Transfer Verification

struct TransferOTPSheet: View {
    @ObservedObject var viewModel: TransferConfirmViewModel
    @State private var otpCode = ""
    @State private var isVerifying = false

    var body: some View {
        NavigationView {
            VStack(spacing: 32) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: "lock.shield.fill")
                        .font(.system(size: 48))
                        .foregroundColor(.accentColor)

                    Text("Enter OTP")
                        .font(.title2)
                        .fontWeight(.semibold)

                    Text("Enter the 6-digit code sent to your registered phone")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .padding(.top, 24)

                // OTP Input
                OTPInputView(otp: $otpCode)
                    .padding(.horizontal, 24)

                // Error Display
                if let error = viewModel.error {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.circle.fill")
                            .foregroundColor(.red)
                        Text(error.localizedDescription)
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                    .padding(.horizontal)
                }

                // Timer info (if otpReference has expiration)
                if let otpRef = viewModel.otpReference {
                    ExpirationTimerView(expiresAt: otpRef.expiresAt)
                }

                // Verify Button
                ActionButton(
                    title: "Verify & Complete",
                    isLoading: isVerifying || viewModel.isSubmitting,
                    isDisabled: otpCode.count != 6,
                    action: {
                        verifyOTP()
                    }
                )
                .padding(.horizontal, 24)

                Spacer()

                // Resend info
                VStack(spacing: 8) {
                    Text("Didn't receive the code?")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Button("Request New Code") {
                        // In a real app, this would request a new OTP
                        otpCode = ""
                    }
                    .font(.caption)
                    .foregroundColor(.accentColor)
                }
                .padding(.bottom, 24)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        viewModel.dismissOTP()
                    }
                }
            }
        }
    }

    private func verifyOTP() {
        isVerifying = true
        Task {
            await viewModel.verifyAndComplete(otpCode: otpCode)
            isVerifying = false
        }
    }
}

// MARK: - Expiration Timer View

struct ExpirationTimerView: View {
    let expiresAt: Date
    @State private var timeRemaining: TimeInterval = 0
    @State private var timer: Timer?

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "clock.fill")
                .font(.caption2)

            Text("Code expires in \(formattedTime)")
                .font(.caption)
        }
        .foregroundColor(timeRemaining < 60 ? .red : .secondary)
        .onAppear {
            updateTimer()
            startTimer()
        }
        .onDisappear {
            timer?.invalidate()
        }
    }

    private var formattedTime: String {
        let minutes = Int(timeRemaining) / 60
        let seconds = Int(timeRemaining) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    private func updateTimer() {
        timeRemaining = max(0, expiresAt.timeIntervalSince(Date()))
    }

    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            updateTimer()
            if timeRemaining <= 0 {
                timer?.invalidate()
            }
        }
    }
}

// MARK: - Preview

#if DEBUG
struct TransferConfirmView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            TransferConfirmView(
                viewModel: previewViewModel
            )
        }
    }

    static var previewViewModel: TransferConfirmViewModel {
        let vm = TransferConfirmViewModel(
            transferRequest: TransferRequest(
                type: .internal,
                sourceAccountId: "ACC001",
                destinationAccountId: "ACC002",
                amount: 500.00,
                currency: "ALL",
                description: "Monthly savings"
            ),
            transferService: MockTransferService(),
            accountService: MockAccountService(),
            beneficiaryService: MockBeneficiaryService(),
            coordinator: nil
        )

        // Set preview data
        vm.sourceAccount = Account(
            id: "ACC001",
            accountNumber: "1234567890",
            accountType: .checking,
            currency: "ALL",
            balance: 5000,
            availableBalance: 5000,
            accountName: "Primary Checking",
            iban: nil,
            isDefault: true
        )

        vm.destinationAccount = Account(
            id: "ACC002",
            accountNumber: "0987654321",
            accountType: .savings,
            currency: "ALL",
            balance: 10000,
            availableBalance: 10000,
            accountName: "Emergency Savings",
            iban: nil,
            isDefault: false
        )

        return vm
    }
}
#endif
