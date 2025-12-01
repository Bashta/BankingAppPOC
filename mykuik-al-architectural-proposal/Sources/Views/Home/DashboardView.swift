//
//  DashboardView.swift
//  BankingApp
//
//  Dashboard/Home screen showing account summaries and quick actions.
//  Story 6.1: Implement Dashboard View with Account Summaries
//

import SwiftUI

// MARK: - DashboardView

/// Main dashboard view displaying financial overview and navigation.
///
/// Features:
/// - Total balance card with show/hide toggle (AC: #7)
/// - Notification bell with unread badge (AC: #8)
/// - Quick actions row (AC: #9)
/// - Account summary cards in horizontal scroll (AC: #10)
/// - Recent transactions list (AC: #12)
/// - Pull-to-refresh (AC: #13)
/// - Loading and error states (AC: #6, #14)
struct DashboardView: View {
    @ObservedObject var viewModel: DashboardViewModel

    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.accounts.isEmpty {
                // Loading state (AC: #6)
                LoadingView(message: "Loading your dashboard...")
            } else if let error = viewModel.error, viewModel.accounts.isEmpty {
                // Error state (AC: #14)
                ErrorView(
                    message: "Unable to load dashboard. \(error.localizedDescription)",
                    retryAction: {
                        Task {
                            await viewModel.loadData()
                        }
                    }
                )
            } else {
                // Content state
                dashboardContent
            }
        }
        .navigationTitle("Home")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                notificationBellButton
            }
        }
        .task {
            await viewModel.loadData()
        }
    }

    // MARK: - Dashboard Content

    private var dashboardContent: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Total Balance Card (AC: #7)
                totalBalanceCard

                // Quick Actions (AC: #9)
                quickActionsSection

                // My Accounts Section (AC: #10)
                accountsSummarySection

                // Recent Activity Section (AC: #12)
                recentActivitySection
            }
            .padding(.vertical)
        }
        .refreshable {
            // Pull-to-refresh (AC: #13)
            await viewModel.refresh()
        }
    }

    // MARK: - Total Balance Card (AC: #7)

    private var totalBalanceCard: some View {
        VStack(spacing: 8) {
            // Label
            Text("Total Balance")
                .font(.subheadline)
                .foregroundColor(.secondary)

            // Balance with visibility toggle
            HStack(alignment: .center, spacing: 12) {
                if viewModel.showBalance {
                    Text(viewModel.totalBalance.formatted(currency: "USD"))
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(.primary)
                } else {
                    Text("****")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(.primary)
                }

                Button(action: {
                    viewModel.toggleBalanceVisibility()
                }) {
                    Image(systemName: viewModel.showBalance ? "eye.fill" : "eye.slash.fill")
                        .font(.title3)
                        .foregroundColor(.secondary)
                }
                .accessibilityLabel(viewModel.showBalance ? "Hide balance" : "Show balance")
            }

            // Last updated
            Text("Just now")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .padding(.horizontal)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        .padding(.horizontal)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Total balance, \(viewModel.showBalance ? viewModel.totalBalance.formatted(currency: "USD") : "hidden")")
    }

    // MARK: - Notification Bell (AC: #8)

    private var notificationBellButton: some View {
        Button(action: {
            viewModel.showNotifications()
        }) {
            ZStack(alignment: .topTrailing) {
                Image(systemName: "bell.fill")
                    .font(.title3)
                    .foregroundColor(.primary)

                // Badge for unread count
                if viewModel.unreadNotificationCount > 0 {
                    Text("\(min(viewModel.unreadNotificationCount, 99))")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(4)
                        .background(Color.red)
                        .clipShape(Circle())
                        .offset(x: 8, y: -8)
                }
            }
        }
        .accessibilityLabel("Notifications, \(viewModel.unreadNotificationCount) unread")
        .accessibilityHint("Double tap to view notifications")
    }

    // MARK: - Quick Actions Section (AC: #9)

    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            QuickActionsRow(actions: [
                QuickAction(
                    title: "Transfer",
                    icon: "arrow.left.arrow.right",
                    action: viewModel.navigateToTransfer
                ),
                QuickAction(
                    title: "Cards",
                    icon: "creditcard",
                    action: viewModel.navigateToCards
                ),
                QuickAction(
                    title: "More",
                    icon: "ellipsis",
                    action: viewModel.navigateToMore
                )
            ])
        }
        .padding(.horizontal)
    }

    // MARK: - Accounts Summary Section (AC: #10)

    private var accountsSummarySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Section Header
            Text("My Accounts")
                .font(.headline)
                .padding(.horizontal)

            if viewModel.accounts.isEmpty {
                // Empty state
                EmptyStateView(
                    iconName: "wallet.pass",
                    title: "No Accounts",
                    message: "You don't have any accounts yet."
                )
                .padding(.horizontal)
            } else {
                // Horizontal scroll of account cards
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(viewModel.accounts) { account in
                            AccountSummaryCard(
                                account: account,
                                showBalance: viewModel.showBalance,
                                onTap: {
                                    viewModel.showAccountDetail(account)
                                }
                            )
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
    }

    // MARK: - Recent Activity Section (AC: #12)

    private var recentActivitySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Section Header
            Text("Recent Activity")
                .font(.headline)
                .padding(.horizontal)

            if viewModel.recentTransactions.isEmpty {
                // Empty state
                EmptyStateView(
                    iconName: "list.bullet.rectangle",
                    title: "No Recent Transactions",
                    message: "Your recent transactions will appear here."
                )
                .padding(.horizontal)
            } else {
                // Transaction list
                VStack(spacing: 0) {
                    ForEach(viewModel.recentTransactions) { transaction in
                        Button(action: {
                            viewModel.showTransactionDetail(transaction)
                        }) {
                            TransactionCell(transaction: transaction)
                        }
                        .buttonStyle(.plain)

                        if transaction.id != viewModel.recentTransactions.last?.id {
                            Divider()
                                .padding(.leading, 52)
                        }
                    }
                }
                .padding(.horizontal)
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .padding(.horizontal)
            }
        }
    }
}
