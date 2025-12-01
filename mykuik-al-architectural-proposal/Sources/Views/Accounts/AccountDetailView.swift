//
//  AccountDetailView.swift
//  BankingApp
//
//  Account detail view with balance card, quick actions, and recent transactions.
//  Story 3.2: Implement Account Detail View with Balance Card
//

import SwiftUI

struct AccountDetailView: View {
    @ObservedObject var viewModel: AccountDetailViewModel

    var body: some View {
        contentView
            .navigationTitle("Account Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: viewModel.toggleBalanceVisibility) {
                        Image(systemName: viewModel.showBalance ? "eye" : "eye.slash")
                    }
                    .accessibilityLabel(viewModel.showBalance ? "Hide balance" : "Show balance")
                }
            }
            .onAppear {
                if viewModel.account == nil && !viewModel.isLoading {
                    Task {
                        await viewModel.loadData()
                    }
                }
            }
    }

    @ViewBuilder
    private var contentView: some View {
        if let account = viewModel.account {
            content(account: account)
        } else if viewModel.error != nil {
            ErrorView(
                message: "Unable to load account details. Please try again.",
                retryAction: { Task { await viewModel.loadData() } }
            )
        } else {
            // Default: show loading (covers initial state and isLoading state)
            LoadingView(message: "Loading account details...")
        }
    }

    private func content(account: Account) -> some View {
        ScrollView {
            VStack(spacing: 16) {
                // Balance Card
                AccountBalanceCard(
                    account: account,
                    showBalance: viewModel.showBalance,
                    onToggle: viewModel.toggleBalanceVisibility,
                    onSetDefault: account.isDefault ? nil : {
                        Task { await viewModel.setAsDefault() }
                    }
                )

                // Quick Actions
                QuickActionsRow(actions: [
                    QuickAction(
                        title: "Transfer",
                        icon: "arrow.right.circle.fill",
                        action: viewModel.initiateTransfer
                    ),
                    QuickAction(
                        title: "Statement",
                        icon: "doc.text.fill",
                        action: viewModel.downloadStatement
                    )
                ])

                // Recent Transactions
                if !viewModel.recentTransactions.isEmpty {
                    recentTransactionsSection
                }
            }
            .padding()
        }
        .refreshable {
            await viewModel.refresh()
        }
    }

    private var recentTransactionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recent Activity")
                    .font(.headline)
                Spacer()
                Button("See All") {
                    viewModel.showAllTransactions()
                }
                .font(.subheadline)
            }

            VStack(spacing: 0) {
                ForEach(viewModel.recentTransactions) { transaction in
                    Button(action: { viewModel.showTransactionDetail(transaction) }) {
                        TransactionCell(transaction: transaction)
                    }
                    .buttonStyle(.plain)

                    if transaction.id != viewModel.recentTransactions.last?.id {
                        Divider()
                    }
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
        }
    }
}
