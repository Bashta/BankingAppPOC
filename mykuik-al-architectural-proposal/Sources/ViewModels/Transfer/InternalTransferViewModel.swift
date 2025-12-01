//
//  InternalTransferViewModel.swift
//  BankingApp
//
//  ViewModel for internal transfer flow (transferring between own accounts)
//

import Foundation
import Combine
import OSLog

final class InternalTransferViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published var sourceAccount: Account?
    @Published var destinationAccount: Account?
    @Published var amount: Decimal = 0
    @Published var transferDescription: String = ""
    @Published var accounts: [Account] = []
    @Published var isLoading = false
    @Published var validationError: String?

    // MARK: - Dependencies

    private let accountService: AccountServiceProtocol
    private let transferService: TransferServiceProtocol
    private let preselectedAccountId: String?
    weak var coordinator: TransferCoordinator?

    // MARK: - Computed Properties

    /// Returns all accounts except the currently selected source account
    var availableDestinationAccounts: [Account] {
        guard let source = sourceAccount else { return accounts }
        return accounts.filter { $0.id != source.id }
    }

    /// Returns true when all form validation rules pass
    var isFormValid: Bool {
        guard let source = sourceAccount,
              let destination = destinationAccount else {
            return false
        }

        // Source != destination
        if source.id == destination.id {
            return false
        }

        // Amount > 0
        if amount <= 0 {
            return false
        }

        // Amount <= available balance
        if amount > source.availableBalance {
            return false
        }

        return true
    }

    /// Available balance from the selected source account
    var sourceAvailableBalance: Decimal? {
        sourceAccount?.availableBalance
    }

    /// Currency from the selected source account
    var sourceCurrency: String {
        sourceAccount?.currency ?? "USD"
    }

    // MARK: - Initialization

    init(
        accountService: AccountServiceProtocol,
        transferService: TransferServiceProtocol,
        preselectedAccountId: String? = nil,
        coordinator: TransferCoordinator
    ) {
        self.accountService = accountService
        self.transferService = transferService
        self.preselectedAccountId = preselectedAccountId
        self.coordinator = coordinator
    }

    // MARK: - Public Methods

    @MainActor
    func loadAccounts() async {
        isLoading = true
        validationError = nil
        defer { isLoading = false }

        do {
            accounts = try await accountService.fetchAccounts()
            Logger.transfer.debug("Loaded \(self.accounts.count) accounts for internal transfer")

            // Apply preselection if provided
            if let preselectedId = preselectedAccountId,
               let preselected = accounts.first(where: { $0.id == preselectedId }) {
                sourceAccount = preselected
                Logger.transfer.debug("Pre-selected source account: \(preselected.accountName)")
            }
        } catch {
            validationError = "Unable to load accounts"
            Logger.transfer.error("Failed to load accounts: \(error.localizedDescription)")
        }
    }

    /// Validates the transfer form and returns true if valid
    /// Also updates validationError with appropriate message if invalid
    func validateTransfer() -> Bool {
        // Clear previous error
        validationError = nil

        guard let source = sourceAccount else {
            return false
        }

        guard let destination = destinationAccount else {
            return false
        }

        if source.id == destination.id {
            validationError = "Source and destination cannot be the same"
            return false
        }

        if amount <= 0 {
            return false
        }

        if amount > source.availableBalance {
            validationError = "Amount exceeds available balance"
            return false
        }

        return true
    }

    /// Proceeds to the confirmation screen with the created TransferRequest
    func proceedToConfirmation() {
        guard validateTransfer(),
              let source = sourceAccount,
              let destination = destinationAccount else {
            Logger.transfer.warning("Cannot proceed to confirmation - validation failed")
            return
        }

        let request = TransferRequest(
            type: .internal,
            sourceAccountId: source.id,
            destinationAccountId: destination.id,
            beneficiaryId: nil,
            amount: amount,
            currency: source.currency,
            description: transferDescription.isEmpty ? nil : transferDescription
        )

        Logger.transfer.debug("Proceeding to confirmation for internal transfer")
        coordinator?.push(.confirm(request: request))
    }

    // MARK: - Account Selection

    /// Selects a source account and clears destination if it matches the new source
    func selectSourceAccount(_ account: Account) {
        sourceAccount = account
        // Clear destination if it matches new source
        if destinationAccount?.id == account.id {
            destinationAccount = nil
        }
        // Clear validation error when selection changes
        validationError = nil
        Logger.transfer.debug("Selected source account: \(account.accountName)")
    }

    /// Selects a destination account
    func selectDestinationAccount(_ account: Account) {
        destinationAccount = account
        // Clear validation error when selection changes
        validationError = nil
        Logger.transfer.debug("Selected destination account: \(account.accountName)")
    }

    /// Updates the amount and clears validation error
    func updateAmount(_ newAmount: Decimal) {
        amount = newAmount
        // Clear validation error when amount changes
        if validationError == "Amount exceeds available balance" && newAmount <= (sourceAvailableBalance ?? 0) {
            validationError = nil
        }
    }
}
