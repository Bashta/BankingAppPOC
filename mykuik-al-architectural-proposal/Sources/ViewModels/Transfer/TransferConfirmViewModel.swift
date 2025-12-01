import Foundation
import Combine
import OSLog

final class TransferConfirmViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published var transferRequest: TransferRequest
    @Published var isSubmitting = false
    @Published var error: Error?
    @Published var showOTP = false
    @Published var transferId: String?
    @Published var otpReference: OTPReference?

    // Additional display data
    @Published var sourceAccount: Account?
    @Published var destinationAccount: Account?
    @Published var beneficiary: Beneficiary?
    @Published var isLoadingDisplayData = false

    // MARK: - Dependencies

    private let transferService: TransferServiceProtocol
    private let accountService: AccountServiceProtocol
    private let beneficiaryService: BeneficiaryServiceProtocol
    weak var coordinator: TransferCoordinator?

    // MARK: - Computed Properties

    var sourceAccountDisplay: String {
        if let account = sourceAccount {
            return "\(account.accountName) (\(account.accountNumber.maskedAccountNumber))"
        }
        return "Account ****\(transferRequest.sourceAccountId.suffix(4))"
    }

    var destinationDisplay: String {
        if let beneficiary = beneficiary {
            return "\(beneficiary.name) (\(beneficiary.accountNumber.maskedAccountNumber))"
        }
        if let account = destinationAccount {
            return "\(account.accountName) (\(account.accountNumber.maskedAccountNumber))"
        }
        if let destId = transferRequest.destinationAccountId {
            return "Account ****\(destId.suffix(4))"
        }
        return "Unknown"
    }

    var destinationSubtitle: String? {
        if let beneficiary = beneficiary, let bankName = beneficiary.bankName {
            return bankName
        }
        return nil
    }

    var formattedAmount: String {
        transferRequest.amount.formatted(currency: transferRequest.currency)
    }

    var transferTypeDisplay: String {
        transferRequest.type == .internal ? "Internal Transfer" : "External Transfer"
    }

    var isInternal: Bool {
        transferRequest.type == .internal
    }

    // MARK: - Initialization

    init(
        transferRequest: TransferRequest,
        transferService: TransferServiceProtocol,
        accountService: AccountServiceProtocol,
        beneficiaryService: BeneficiaryServiceProtocol,
        coordinator: TransferCoordinator?
    ) {
        self.transferRequest = transferRequest
        self.transferService = transferService
        self.accountService = accountService
        self.beneficiaryService = beneficiaryService
        self.coordinator = coordinator
    }

    // MARK: - Public Methods

    @MainActor
    func loadDisplayData() async {
        isLoadingDisplayData = true
        defer { isLoadingDisplayData = false }

        // Load source account for display
        do {
            sourceAccount = try await accountService.fetchAccount(id: transferRequest.sourceAccountId)
        } catch {
            Logger.transfer.error("Failed to load source account: \(error.localizedDescription)")
        }

        // Load destination based on transfer type
        if let beneficiaryId = transferRequest.beneficiaryId {
            // External transfer - load beneficiary
            do {
                let beneficiaries = try await beneficiaryService.fetchBeneficiaries()
                beneficiary = beneficiaries.first { $0.id == beneficiaryId }
            } catch {
                Logger.transfer.error("Failed to load beneficiary: \(error.localizedDescription)")
            }
        } else if let destinationAccountId = transferRequest.destinationAccountId {
            // Internal transfer - load destination account
            do {
                destinationAccount = try await accountService.fetchAccount(id: destinationAccountId)
            } catch {
                Logger.transfer.error("Failed to load destination account: \(error.localizedDescription)")
            }
        }
    }

    @MainActor
    func initiateTransfer() async {
        isSubmitting = true
        error = nil
        defer { isSubmitting = false }

        do {
            Logger.transfer.debug("Initiating transfer")
            let transfer = try await transferService.initiateTransfer(request: transferRequest)

            transferId = transfer.id
            otpReference = transfer.otpReference
            showOTP = true

            Logger.transfer.debug("Transfer initiated successfully, OTP required")
        } catch {
            self.error = error
            Logger.transfer.error("Transfer initiation failed: \(error.localizedDescription)")
        }
    }

    @MainActor
    func verifyAndComplete(otpCode: String) async {
        guard let transferId = transferId else {
            error = TransferConfirmError.noTransferId
            return
        }

        isSubmitting = true
        error = nil
        defer { isSubmitting = false }

        do {
            Logger.transfer.debug("Verifying OTP for transfer")
            let transfer = try await transferService.confirmTransfer(
                id: transferId,
                otpCode: otpCode
            )

            showOTP = false

            if transfer.status == .completed {
                Logger.transfer.debug("Transfer completed successfully")
                navigateToReceipt(transferId: transfer.id)
            } else {
                error = TransferConfirmError.unexpectedStatus(transfer.status)
            }
        } catch {
            self.error = error
            Logger.transfer.error("OTP verification failed: \(error.localizedDescription)")
        }
    }

    func cancelTransfer() {
        Logger.transfer.debug("Cancelling transfer confirmation")
        coordinator?.pop()
    }

    func dismissOTP() {
        showOTP = false
        error = nil

        // Optionally cancel the initiated transfer
        if let transferId = transferId {
            Task {
                do {
                    _ = try await transferService.cancelTransfer(id: transferId)
                    Logger.transfer.debug("Initiated transfer cancelled")
                } catch {
                    Logger.transfer.error("Failed to cancel transfer: \(error.localizedDescription)")
                }
            }
        }
    }

    func clearError() {
        error = nil
    }

    // MARK: - Private Methods

    private func navigateToReceipt(transferId: String) {
        coordinator?.push(.receipt(transferId: transferId))
    }
}

// MARK: - Transfer Confirm Errors

enum TransferConfirmError: LocalizedError {
    case noTransferId
    case unexpectedStatus(TransferStatus)

    var errorDescription: String? {
        switch self {
        case .noTransferId:
            return "Transfer ID not found. Please try again."
        case .unexpectedStatus(let status):
            return "Unexpected transfer status: \(status.displayName)"
        }
    }
}
