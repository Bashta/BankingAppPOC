//
//  AccountsListViewModel.swift
//  BankingApp
//
//  ViewModel for the accounts list screen - fetches, sorts, and manages account display state
//

import Foundation
import Combine
import OSLog

final class AccountsListViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published var accounts: [Account] = []
    @Published var isLoading = false
    @Published var isRefreshing = false
    @Published var error: Error?
    @Published var showBalances = true

    // MARK: - Dependencies

    private let accountService: AccountServiceProtocol
    weak var coordinator: AccountsCoordinator?

    // MARK: - Initialization

    init(
        accountService: AccountServiceProtocol,
        coordinator: AccountsCoordinator?
    ) {
        self.accountService = accountService
        self.coordinator = coordinator
    }

    // MARK: - Public Methods

    /// Loads accounts from the service and sorts them (default first, then by type)
    @MainActor
    func loadData() async {
        isLoading = true
        error = nil
        defer { isLoading = false }

        do {
            let fetchedAccounts = try await accountService.fetchAccounts()
            accounts = sortAccounts(fetchedAccounts)
            Logger.accounts.debug("Loaded \(self.accounts.count) accounts")
        } catch {
            self.error = error
            Logger.accounts.error("Failed to load accounts: \(error.localizedDescription)")
        }
    }

    /// Refreshes accounts data (pull-to-refresh) without showing full loading state
    @MainActor
    func refresh() async {
        isRefreshing = true
        defer { isRefreshing = false }

        do {
            let fetchedAccounts = try await accountService.fetchAccounts()
            accounts = sortAccounts(fetchedAccounts)
            error = nil
            Logger.accounts.debug("Refreshed accounts: \(self.accounts.count) loaded")
        } catch {
            self.error = error
            Logger.accounts.error("Failed to refresh accounts: \(error.localizedDescription)")
        }
    }

    /// Navigates to account detail screen
    func showAccountDetail(_ account: Account) {
        coordinator?.push(.detail(accountId: account.id))
    }

    /// Toggles balance visibility on/off
    func toggleBalanceVisibility() {
        showBalances.toggle()
        Logger.accounts.debug("Balance visibility toggled: \(self.showBalances)")
    }

    // MARK: - Private Methods

    /// Sorts accounts: isDefault == true first, then by accountType rawValue
    private func sortAccounts(_ accounts: [Account]) -> [Account] {
        accounts.sorted { account1, account2 in
            if account1.isDefault != account2.isDefault {
                return account1.isDefault
            }
            return account1.accountType.rawValue < account2.accountType.rawValue
        }
    }
}
