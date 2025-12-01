//
//  ExternalTransferViewModel.swift
//  BankingApp
//
//  ViewModel for external transfer flow (transferring to beneficiaries)
//

import Foundation
import Combine
import OSLog

final class ExternalTransferViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published var sourceAccount: Account?
    @Published var selectedBeneficiary: Beneficiary?
    @Published var amount: Decimal = 0
    @Published var transferDescription: String = ""
    @Published var accounts: [Account] = []
    @Published var beneficiaries: [Beneficiary] = []
    @Published var isLoading = false
    @Published var validationError: String?

    // MARK: - Dependencies

    private let accountService: AccountServiceProtocol
    private let transferService: TransferServiceProtocol
    private let beneficiaryService: BeneficiaryServiceProtocol
    weak var coordinator: TransferCoordinator?

    // MARK: - Computed Properties

    /// Returns beneficiaries sorted with favorites first, then others alphabetically
    var sortedBeneficiaries: [Beneficiary] {
        let favorites = beneficiaries.filter { $0.isFavorite }
        let others = beneficiaries.filter { !$0.isFavorite }.sorted { $0.name < $1.name }
        return favorites + others
    }

    /// Returns true when all form validation rules pass
    var isFormValid: Bool {
        guard sourceAccount != nil else { return false }
        guard selectedBeneficiary != nil else { return false }
        guard let source = sourceAccount else { return false }

        // Amount > 0
        if amount <= 0 { return false }

        // Amount <= available balance
        if amount > source.availableBalance { return false }

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

    /// Whether there are any beneficiaries available
    var hasBeneficiaries: Bool {
        !beneficiaries.isEmpty
    }

    // MARK: - Initialization

    init(
        accountService: AccountServiceProtocol,
        transferService: TransferServiceProtocol,
        beneficiaryService: BeneficiaryServiceProtocol,
        coordinator: TransferCoordinator
    ) {
        self.accountService = accountService
        self.transferService = transferService
        self.beneficiaryService = beneficiaryService
        self.coordinator = coordinator
    }

    // MARK: - Public Methods

    /// Loads accounts and beneficiaries in parallel
    @MainActor
    func loadData() async {
        isLoading = true
        validationError = nil
        defer { isLoading = false }

        do {
            async let accountsTask = accountService.fetchAccounts()
            async let beneficiariesTask = beneficiaryService.fetchBeneficiaries()

            let (fetchedAccounts, fetchedBeneficiaries) = try await (accountsTask, beneficiariesTask)
            accounts = fetchedAccounts
            beneficiaries = fetchedBeneficiaries

            Logger.transfer.debug("Loaded \(fetchedAccounts.count) accounts and \(fetchedBeneficiaries.count) beneficiaries for external transfer")
        } catch {
            validationError = "Unable to load data"
            Logger.transfer.error("Failed to load external transfer data: \(error.localizedDescription)")
        }
    }

    /// Validates the transfer form and returns true if valid
    /// Also updates validationError with appropriate message if invalid
    func validateTransfer() -> Bool {
        // Clear previous error
        validationError = nil

        guard sourceAccount != nil else {
            return false
        }

        guard selectedBeneficiary != nil else {
            return false
        }

        guard let source = sourceAccount else {
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
              let beneficiary = selectedBeneficiary else {
            Logger.transfer.warning("Cannot proceed to confirmation - validation failed")
            return
        }

        let request = TransferRequest(
            type: .external,
            sourceAccountId: source.id,
            destinationAccountId: nil,
            beneficiaryId: beneficiary.id,
            amount: amount,
            currency: source.currency,
            description: transferDescription.isEmpty ? nil : transferDescription
        )

        Logger.transfer.debug("Proceeding to confirmation for external transfer to \(beneficiary.name)")
        coordinator?.push(.confirm(request: request))
    }

    /// Navigates to add beneficiary screen
    func navigateToAddBeneficiary() {
        Logger.transfer.debug("Navigating to add beneficiary from external transfer")
        coordinator?.push(.addBeneficiary)
    }

    // MARK: - Selection Methods

    /// Selects a source account
    func selectSourceAccount(_ account: Account) {
        sourceAccount = account
        // Clear validation error when selection changes
        validationError = nil
        Logger.transfer.debug("Selected source account: \(account.accountName)")
    }

    /// Selects a beneficiary
    func selectBeneficiary(_ beneficiary: Beneficiary) {
        selectedBeneficiary = beneficiary
        // Clear validation error when selection changes
        validationError = nil
        Logger.transfer.debug("Selected beneficiary: \(beneficiary.name)")
    }

    /// Updates the amount and clears validation error if needed
    func updateAmount(_ newAmount: Decimal) {
        amount = newAmount
        // Clear validation error when amount changes to valid value
        if validationError == "Amount exceeds available balance" && newAmount <= (sourceAvailableBalance ?? 0) {
            validationError = nil
        }
    }
}
