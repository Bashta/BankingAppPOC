//
//  TransferHomeViewModel.swift
//  BankingApp
//
//  ViewModel for the transfer home screen - manages transfer type selection and recent transfers display
//

import Foundation
import Combine
import OSLog

final class TransferHomeViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published var recentTransfers: [Transfer] = []
    @Published var recentBeneficiaries: [Beneficiary] = []
    @Published var isLoading = false
    @Published var isRefreshing = false
    @Published var error: Error?

    // MARK: - Dependencies

    private let transferService: TransferServiceProtocol
    private let beneficiaryService: BeneficiaryServiceProtocol
    weak var coordinator: TransferCoordinator?

    // MARK: - Initialization

    init(
        transferService: TransferServiceProtocol,
        beneficiaryService: BeneficiaryServiceProtocol,
        coordinator: TransferCoordinator?
    ) {
        self.transferService = transferService
        self.beneficiaryService = beneficiaryService
        self.coordinator = coordinator
    }

    // MARK: - Public Methods

    /// Loads recent transfers and beneficiaries from services
    /// Only loads if data hasn't been loaded yet (prevents re-fetching on back navigation)
    @MainActor
    func loadData() async {
        // Skip if data is already loaded to prevent clearing on back navigation
        guard recentTransfers.isEmpty else { return }

        isLoading = true
        error = nil
        defer { isLoading = false }

        do {
            async let transfersTask = transferService.fetchRecentTransfers(limit: 5)
            async let beneficiariesTask = beneficiaryService.fetchBeneficiaries()

            let (transfers, beneficiaries) = try await (transfersTask, beneficiariesTask)
            self.recentTransfers = transfers
            self.recentBeneficiaries = beneficiaries

            Logger.transfer.debug("Loaded \(transfers.count) recent transfers, \(beneficiaries.count) beneficiaries")
        } catch {
            self.error = error
            Logger.transfer.error("Failed to load transfer home data: \(error.localizedDescription)")
        }
    }

    /// Refreshes data (pull-to-refresh) without showing full loading state
    @MainActor
    func refresh() async {
        isRefreshing = true
        defer { isRefreshing = false }

        do {
            async let transfersTask = transferService.fetchRecentTransfers(limit: 5)
            async let beneficiariesTask = beneficiaryService.fetchBeneficiaries()

            let (transfers, beneficiaries) = try await (transfersTask, beneficiariesTask)
            self.recentTransfers = transfers
            self.recentBeneficiaries = beneficiaries
            error = nil

            Logger.transfer.debug("Refreshed transfer home: \(transfers.count) transfers, \(beneficiaries.count) beneficiaries")
        } catch {
            self.error = error
            Logger.transfer.error("Failed to refresh transfer home data: \(error.localizedDescription)")
        }
    }

    // MARK: - Navigation Methods

    /// Navigates to internal transfer (between own accounts)
    func startInternalTransfer() {
        coordinator?.push(.internalTransfer)
        Logger.transfer.debug("Navigating to internal transfer")
    }

    /// Navigates to external transfer (to beneficiary)
    func startExternalTransfer() {
        coordinator?.push(.externalTransfer)
        Logger.transfer.debug("Navigating to external transfer")
    }

    /// Navigates to beneficiary management list
    func showBeneficiaries() {
        coordinator?.push(.beneficiaryList)
        Logger.transfer.debug("Navigating to beneficiary list")
    }

    /// Navigates to transfer detail/receipt view
    func showTransferDetail(_ transfer: Transfer) {
        coordinator?.push(.receipt(transferId: transfer.id))
        Logger.transfer.debug("Navigating to transfer detail: \(transfer.id)")
    }
}
