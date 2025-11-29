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

    init(dependencyContainer: DependencyContainer) {
        self.dependencyContainer = dependencyContainer
    }

    // MARK: - Accounts Feature Views

    func makeAccountsListView(coordinator: AccountsCoordinator) -> some View {
        let viewModel = AccountsListViewModel(
            accountService: dependencyContainer.accountService,
            coordinator: coordinator
        )
        return AccountsListView(viewModel: viewModel)
    }

    func makeAccountDetailView(accountId: String, coordinator: AccountsCoordinator) -> some View {
        let viewModel = AccountDetailViewModel(
            accountId: accountId,
            accountService: dependencyContainer.accountService,
            transactionService: dependencyContainer.transactionService,
            coordinator: coordinator
        )
        return AccountDetailView(viewModel: viewModel)
    }

    func makeTransactionHistoryView(accountId: String, coordinator: AccountsCoordinator) -> some View {
        let viewModel = TransactionHistoryViewModel(
            accountId: accountId,
            transactionService: dependencyContainer.transactionService,
            coordinator: coordinator
        )
        return TransactionHistoryView(viewModel: viewModel)
    }

    func makeTransactionDetailView(transactionId: String, coordinator: AccountsCoordinator) -> some View {
        let viewModel = TransactionDetailViewModel(
            transactionId: transactionId,
            transactionService: dependencyContainer.transactionService,
            coordinator: coordinator
        )
        return TransactionDetailView(viewModel: viewModel)
    }

    func makeStatementView(accountId: String, coordinator: AccountsCoordinator) -> some View {
        let viewModel = StatementViewModel(
            accountId: accountId,
            transactionService: dependencyContainer.transactionService,
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
