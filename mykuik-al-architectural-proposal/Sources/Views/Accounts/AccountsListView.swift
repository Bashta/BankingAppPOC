//
//  AccountsListView.swift
//  BankingApp
//
//  Displays the list of user accounts with pull-to-refresh and balance visibility toggle
//

import SwiftUI

struct AccountsListView: View {
    @ObservedObject var viewModel: AccountsListViewModel

    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.accounts.isEmpty {
                LoadingView(message: "Loading accounts...")
            } else if let error = viewModel.error, viewModel.accounts.isEmpty {
                ErrorView(
                    message: "Unable to load accounts. Please try again.",
                    retryAction: { Task { await viewModel.loadData() } }
                )
            } else if viewModel.accounts.isEmpty {
                EmptyStateView(
                    iconName: "wallet.pass",
                    title: "No Accounts",
                    message: "You don't have any accounts yet."
                )
            } else {
                accountsList
            }
        }
        .navigationTitle("Accounts")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: viewModel.toggleBalanceVisibility) {
                    Image(systemName: viewModel.showBalances ? "eye" : "eye.slash")
                }
                .accessibilityLabel(viewModel.showBalances ? "Hide balances" : "Show balances")
            }
        }
        .task {
            await viewModel.loadData()
        }
    }

    // MARK: - Accounts List

    private var accountsList: some View {
        List {
            ForEach(viewModel.accounts) { account in
                Button(action: { viewModel.showAccountDetail(account) }) {
                    AccountCell(account: account, showBalance: viewModel.showBalances)
                }
                .buttonStyle(.plain)
            }
        }
        .refreshable {
            await viewModel.refresh()
        }
    }
}

// MARK: - Preview

#Preview("AccountsListView - Loading") {
    NavigationView {
        AccountsListView(viewModel: AccountsListViewModelPreview.loading)
    }
    .navigationViewStyle(.stack)
}

#Preview("AccountsListView - With Data") {
    NavigationView {
        AccountsListView(viewModel: AccountsListViewModelPreview.withData)
    }
    .navigationViewStyle(.stack)
}

#Preview("AccountsListView - Empty") {
    NavigationView {
        AccountsListView(viewModel: AccountsListViewModelPreview.empty)
    }
    .navigationViewStyle(.stack)
}

// MARK: - Preview Helper

private enum AccountsListViewModelPreview {
    static var loading: AccountsListViewModel {
        let vm = AccountsListViewModel(
            accountService: MockAccountService(),
            coordinator: nil
        )
        vm.isLoading = true
        return vm
    }

    static var withData: AccountsListViewModel {
        let vm = AccountsListViewModel(
            accountService: MockAccountService(),
            coordinator: nil
        )
        vm.accounts = [
            Account(
                id: "ACC001",
                accountNumber: "1234567890",
                accountType: .checking,
                currency: "USD",
                balance: 5432.50,
                availableBalance: 5232.50,
                accountName: "Primary Checking",
                iban: "US12345678901234567890",
                isDefault: true
            ),
            Account(
                id: "ACC002",
                accountNumber: "0987654321",
                accountType: .savings,
                currency: "USD",
                balance: 15000.00,
                availableBalance: 15000.00,
                accountName: "Emergency Savings",
                iban: nil,
                isDefault: false
            )
        ]
        return vm
    }

    static var empty: AccountsListViewModel {
        let vm = AccountsListViewModel(
            accountService: MockAccountService(),
            coordinator: nil
        )
        return vm
    }
}
