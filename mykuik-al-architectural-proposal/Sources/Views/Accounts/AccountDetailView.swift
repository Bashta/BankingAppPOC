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

// MARK: - Preview

#Preview("AccountDetailView - Loading") {
    NavigationView {
        AccountDetailView(
            viewModel: makePreviewViewModel(isLoading: true)
        )
    }
}

#Preview("AccountDetailView - Loaded") {
    NavigationView {
        AccountDetailView(
            viewModel: makePreviewViewModel(isLoading: false)
        )
    }
}

// MARK: - Preview Helper

private func makePreviewViewModel(isLoading: Bool) -> AccountDetailViewModel {
    let viewModel = AccountDetailViewModel(
        accountId: "ACC001",
        accountService: PreviewAccountService(),
        transactionService: PreviewTransactionService(),
        coordinator: nil
    )

    if isLoading {
        viewModel.isLoading = true
    } else {
        viewModel.account = Account(
            id: "ACC001",
            accountNumber: "1234567890",
            accountType: .checking,
            currency: "USD",
            balance: 5432.50,
            availableBalance: 5232.50,
            accountName: "Primary Checking",
            iban: "US12345678901234567890",
            isDefault: true
        )
        viewModel.recentTransactions = [
            Transaction(
                id: "TXN001",
                accountId: "ACC001",
                type: .debit,
                amount: 45.99,
                currency: "USD",
                description: "Amazon Purchase",
                merchantName: "Amazon",
                category: .purchase,
                date: Date().addingTimeInterval(-86400),
                status: .completed,
                reference: "AMZ12345",
                balance: 5386.51
            ),
            Transaction(
                id: "TXN002",
                accountId: "ACC001",
                type: .credit,
                amount: 3500.00,
                currency: "USD",
                description: "Salary Deposit",
                merchantName: nil,
                category: .salary,
                date: Date().addingTimeInterval(-172800),
                status: .completed,
                reference: "SAL67890",
                balance: 5432.50
            )
        ]
    }

    return viewModel
}

private struct PreviewAccountService: AccountServiceProtocol {
    func fetchAccounts() async throws -> [Account] { [] }
    func fetchAccount(id: String) async throws -> Account {
        Account(
            id: id,
            accountNumber: "1234567890",
            accountType: .checking,
            currency: "USD",
            balance: 5432.50,
            availableBalance: 5232.50,
            accountName: "Primary Checking",
            iban: nil,
            isDefault: true
        )
    }
    func updateAccount(id: String, updates: AccountUpdates) async throws -> Account {
        try await fetchAccount(id: id)
    }
    func setDefaultAccount(id: String) async throws {}
}

private struct PreviewTransactionService: TransactionServiceProtocol {
    func fetchTransactions(accountId: String, page: Int, limit: Int) async throws -> TransactionPage {
        TransactionPage(transactions: [], currentPage: 1, totalPages: 1, totalItems: 0)
    }
    func fetchTransaction(id: String) async throws -> Transaction {
        Transaction(
            id: id,
            accountId: "ACC001",
            type: .debit,
            amount: 10,
            currency: "USD",
            description: "Test",
            merchantName: nil,
            category: .other,
            date: Date(),
            status: .completed,
            reference: nil,
            balance: nil
        )
    }
    func searchTransactions(accountId: String, query: String) async throws -> [Transaction] { [] }
    func filterTransactions(accountId: String, dateRange: (Date, Date)?, categories: Set<TransactionCategory>) async throws -> [Transaction] { [] }
}
