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
