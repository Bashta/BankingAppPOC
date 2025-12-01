//
//  AccountsViewFactory.swift
//  BankingApp
//
//  View factory for Accounts feature that creates View+ViewModel pairs
//  for all account-related screens (list, detail, transactions, statements).
//

import SwiftUI

final class AccountsViewFactory {
    private let dependencyContainer: DependencyContainer

    // Cached ViewModels to prevent recreation on navigation state changes
    private var cachedAccountsListViewModel: AccountsListViewModel?
    private var cachedAccountDetailViewModels: [String: AccountDetailViewModel] = [:]
    private var cachedTransactionHistoryViewModels: [String: TransactionHistoryViewModel] = [:]
    private var cachedTransactionDetailViewModels: [String: TransactionDetailViewModel] = [:]

    init(dependencyContainer: DependencyContainer) {
        self.dependencyContainer = dependencyContainer
    }

    /// Clears all cached ViewModels - call when user logs out or navigation resets
    func clearCache() {
        cachedAccountsListViewModel = nil
        cachedAccountDetailViewModels.removeAll()
        cachedTransactionHistoryViewModels.removeAll()
        cachedTransactionDetailViewModels.removeAll()
    }

    // MARK: - Accounts Feature Views

    func makeAccountsListView(coordinator: AccountsCoordinator) -> some View {
        if cachedAccountsListViewModel == nil {
            cachedAccountsListViewModel = AccountsListViewModel(
                accountService: dependencyContainer.accountService,
                coordinator: coordinator
            )
        }
        return AccountsListView(viewModel: cachedAccountsListViewModel!)
    }

    func makeAccountDetailView(accountId: String, coordinator: AccountsCoordinator) -> some View {
        if cachedAccountDetailViewModels[accountId] == nil {
            cachedAccountDetailViewModels[accountId] = AccountDetailViewModel(
                accountId: accountId,
                accountService: dependencyContainer.accountService,
                transactionService: dependencyContainer.transactionService,
                coordinator: coordinator
            )
        }
        return AccountDetailView(viewModel: cachedAccountDetailViewModels[accountId]!)
    }

    func makeTransactionHistoryView(accountId: String, coordinator: AccountsCoordinator) -> some View {
        if cachedTransactionHistoryViewModels[accountId] == nil {
            cachedTransactionHistoryViewModels[accountId] = TransactionHistoryViewModel(
                accountId: accountId,
                transactionService: dependencyContainer.transactionService,
                coordinator: coordinator
            )
        }
        return TransactionHistoryView(viewModel: cachedTransactionHistoryViewModels[accountId]!)
    }

    func makeTransactionDetailView(transactionId: String, coordinator: AccountsCoordinator) -> some View {
        if cachedTransactionDetailViewModels[transactionId] == nil {
            cachedTransactionDetailViewModels[transactionId] = TransactionDetailViewModel(
                transactionId: transactionId,
                transactionService: dependencyContainer.transactionService,
                coordinator: coordinator
            )
        }
        return TransactionDetailView(viewModel: cachedTransactionDetailViewModels[transactionId]!)
    }

    func makeStatementView(accountId: String, coordinator: AccountsCoordinator) -> some View {
        let viewModel = StatementViewModel(
            accountId: accountId,
            accountService: dependencyContainer.accountService,
            coordinator: coordinator
        )
        return StatementView(viewModel: viewModel)
    }

    func makeStatementDownloadView(accountId: String, month: Int, year: Int, coordinator: AccountsCoordinator) -> some View {
        let viewModel = StatementDownloadViewModel(
            accountId: accountId,
            month: month,
            year: year,
            transactionService: dependencyContainer.transactionService,
            coordinator: coordinator
        )
        return StatementDownloadView(viewModel: viewModel)
    }
}
