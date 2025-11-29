//
//  AccountDetailViewModel.swift
//  BankingApp
//
//  ViewModel for account detail screen - displays account info, recent transactions, and quick actions.
//  Story 3.2: Implement Account Detail View with Balance Card
//

import Foundation
import Combine
import OSLog

final class AccountDetailViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published var account: Account?
    @Published var recentTransactions: [Transaction] = []
    @Published var isLoading = false
    @Published var isRefreshing = false
    @Published var error: Error?
    @Published var showBalance = true

    // MARK: - Properties

    let accountId: String

    // MARK: - Dependencies

    private let accountService: AccountServiceProtocol
    private let transactionService: TransactionServiceProtocol
    weak var coordinator: AccountsCoordinator?

    // MARK: - Initialization

    init(
        accountId: String,
        accountService: AccountServiceProtocol,
        transactionService: TransactionServiceProtocol,
        coordinator: AccountsCoordinator?
    ) {
        self.accountId = accountId
        self.accountService = accountService
        self.transactionService = transactionService
        self.coordinator = coordinator
    }

    // MARK: - Public Methods

    /// Loads account and recent transactions in parallel using async let
    @MainActor
    func loadData() async {
        isLoading = true
        error = nil
        defer { isLoading = false }

        do {
            async let accountTask = accountService.fetchAccount(id: accountId)
            async let transactionsTask = transactionService.fetchTransactions(
                accountId: accountId,
                page: 1,
                limit: 5
            )

            let (fetchedAccount, page) = try await (accountTask, transactionsTask)
            self.account = fetchedAccount
            self.recentTransactions = page.transactions

            Logger.accounts.debug("Loaded account \(self.accountId) with \(page.transactions.count) recent transactions")
        } catch {
            self.error = error
            Logger.accounts.error("Failed to load account detail for \(self.accountId): \(error.localizedDescription)")
        }
    }

    /// Refreshes account data (pull-to-refresh) without showing full loading state
    @MainActor
    func refresh() async {
        isRefreshing = true
        defer { isRefreshing = false }

        do {
            async let accountTask = accountService.fetchAccount(id: accountId)
            async let transactionsTask = transactionService.fetchTransactions(
                accountId: accountId,
                page: 1,
                limit: 5
            )

            let (fetchedAccount, page) = try await (accountTask, transactionsTask)
            self.account = fetchedAccount
            self.recentTransactions = page.transactions
            self.error = nil

            Logger.accounts.debug("Refreshed account \(self.accountId)")
        } catch {
            self.error = error
            Logger.accounts.error("Failed to refresh account \(self.accountId): \(error.localizedDescription)")
        }
    }

    /// Toggles balance visibility on/off
    func toggleBalanceVisibility() {
        showBalance.toggle()
        Logger.accounts.debug("Balance visibility toggled: \(self.showBalance)")
    }

    /// Navigates to full transaction history
    func showAllTransactions() {
        coordinator?.push(.transactions(accountId: accountId))
    }

    /// Navigates to transaction detail screen
    func showTransactionDetail(_ transaction: Transaction) {
        coordinator?.push(.transactionDetail(transactionId: transaction.id))
    }

    /// Initiates transfer from this account - cross-feature navigation
    func initiateTransfer() {
        coordinator?.navigateToTransfer(fromAccountId: accountId)
    }

    /// Navigates to statement/download screen
    func downloadStatement() {
        coordinator?.push(.statement(accountId: accountId))
    }

    /// Sets this account as the default account
    @MainActor
    func setAsDefault() async {
        do {
            try await accountService.setDefaultAccount(id: accountId)
            // Refresh to show updated state
            await loadData()
            Logger.accounts.debug("Set account \(self.accountId) as default")
        } catch {
            self.error = error
            Logger.accounts.error("Failed to set account \(self.accountId) as default: \(error.localizedDescription)")
        }
    }
}
