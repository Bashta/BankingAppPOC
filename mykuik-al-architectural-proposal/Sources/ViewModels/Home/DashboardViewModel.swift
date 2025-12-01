//
//  DashboardViewModel.swift
//  BankingApp
//
//  ViewModel for the Dashboard/Home screen.
//  Story 6.1: Implement Dashboard View with Account Summaries
//

import Foundation
import Combine
import OSLog

// MARK: - DashboardViewModel

/// ViewModel managing dashboard state, data loading, and navigation for the home screen.
///
/// Responsibilities:
/// - Aggregates data from Account, Transaction, and Notification services
/// - Manages loading/refresh states and error handling
/// - Handles balance visibility preference with UserDefaults persistence
/// - Delegates navigation to HomeCoordinator
///
/// Data Flow:
/// - loadData() performs parallel async fetches from all three services
/// - Updates @Published properties triggering SwiftUI re-renders
/// - Navigation methods call weak coordinator reference
final class DashboardViewModel: ObservableObject {

    // MARK: - Published Properties (AC: #1)

    /// All user accounts for summary display
    @Published var accounts: [Account] = []

    /// Recent transactions across all accounts (limit 10)
    @Published var recentTransactions: [Transaction] = []

    /// Unread notification count for badge display
    @Published var unreadNotificationCount: Int = 0

    /// Total balance across all accounts (sum of account.balance)
    @Published var totalBalance: Decimal = 0

    /// Loading state for initial data fetch
    @Published var isLoading = false

    /// Refreshing state for pull-to-refresh
    @Published var isRefreshing = false

    /// Error state for displaying ErrorView
    @Published var error: Error?

    /// Balance visibility toggle (persisted to UserDefaults)
    @Published var showBalance: Bool

    // MARK: - Private Properties

    /// UserDefaults key for balance visibility preference
    private let showBalanceKey = "dashboardShowBalance"

    /// Account service for fetching accounts
    private let accountService: AccountServiceProtocol

    /// Transaction service for fetching recent transactions
    private let transactionService: TransactionServiceProtocol

    /// Notification service for fetching unread count
    private let notificationService: NotificationServiceProtocol

    /// Weak coordinator reference for navigation (AC: #5)
    private weak var coordinator: HomeCoordinator?

    // MARK: - Initialization (AC: #4)

    /// Creates DashboardViewModel with required dependencies.
    ///
    /// - Parameters:
    ///   - accountService: Service for account data
    ///   - transactionService: Service for transaction data
    ///   - notificationService: Service for notification data
    ///   - coordinator: HomeCoordinator for navigation (weak reference)
    init(
        accountService: AccountServiceProtocol,
        transactionService: TransactionServiceProtocol,
        notificationService: NotificationServiceProtocol,
        coordinator: HomeCoordinator
    ) {
        self.accountService = accountService
        self.transactionService = transactionService
        self.notificationService = notificationService
        self.coordinator = coordinator

        // Load balance visibility preference from UserDefaults (AC: #4)
        self.showBalance = UserDefaults.standard.bool(forKey: showBalanceKey)
        // If key doesn't exist, default to true
        if !UserDefaults.standard.contains(key: showBalanceKey) {
            self.showBalance = true
        }

        Logger.home.debug("DashboardViewModel initialized")
    }

    // MARK: - Data Loading (AC: #2)

    /// Loads all dashboard data with parallel async fetches.
    ///
    /// Flow:
    /// 1. Set isLoading = true
    /// 2. Parallel fetch: accounts, recent transactions (limit 10), unread count
    /// 3. Calculate totalBalance as sum of all account balances
    /// 4. Update @Published properties
    /// 5. Set isLoading = false
    /// 6. On error: set error property
    @MainActor
    func loadData() async {
        Logger.home.debug("Dashboard loadData() started")
        isLoading = true
        error = nil

        defer { isLoading = false }

        do {
            // Parallel fetch from all services
            async let accountsTask = accountService.fetchAccounts()
            async let transactionsTask = transactionService.fetchRecentTransactions(limit: 10)
            async let unreadCountTask = notificationService.getUnreadCount()

            let (fetchedAccounts, fetchedTransactions, fetchedUnreadCount) = try await (
                accountsTask,
                transactionsTask,
                unreadCountTask
            )

            // Update published properties
            self.accounts = fetchedAccounts
            self.recentTransactions = fetchedTransactions
            self.unreadNotificationCount = fetchedUnreadCount

            // Calculate total balance as sum of all account balances
            self.totalBalance = fetchedAccounts.reduce(Decimal(0)) { $0 + $1.balance }

            Logger.home.info("Dashboard loaded: \(fetchedAccounts.count) accounts, \(fetchedTransactions.count) transactions, \(fetchedUnreadCount) unread notifications, total balance: \(self.totalBalance)")

        } catch {
            Logger.home.error("Dashboard loadData() failed: \(error.localizedDescription)")
            self.error = error
        }
    }

    // MARK: - Refresh (AC: #3)

    /// Refreshes dashboard data for pull-to-refresh.
    ///
    /// Flow:
    /// 1. Set isRefreshing = true
    /// 2. Call loadData() logic
    /// 3. Set isRefreshing = false
    @MainActor
    func refresh() async {
        Logger.home.debug("Dashboard refresh() started")
        isRefreshing = true

        defer { isRefreshing = false }

        // Clear error before refresh
        error = nil

        do {
            async let accountsTask = accountService.fetchAccounts()
            async let transactionsTask = transactionService.fetchRecentTransactions(limit: 10)
            async let unreadCountTask = notificationService.getUnreadCount()

            let (fetchedAccounts, fetchedTransactions, fetchedUnreadCount) = try await (
                accountsTask,
                transactionsTask,
                unreadCountTask
            )

            self.accounts = fetchedAccounts
            self.recentTransactions = fetchedTransactions
            self.unreadNotificationCount = fetchedUnreadCount
            self.totalBalance = fetchedAccounts.reduce(Decimal(0)) { $0 + $1.balance }

            Logger.home.info("Dashboard refreshed successfully")

        } catch {
            Logger.home.error("Dashboard refresh() failed: \(error.localizedDescription)")
            self.error = error
        }
    }

    // MARK: - Balance Visibility Toggle (AC: #4)

    /// Toggles balance visibility and persists to UserDefaults.
    func toggleBalanceVisibility() {
        showBalance.toggle()
        UserDefaults.standard.set(showBalance, forKey: showBalanceKey)
        Logger.home.debug("Balance visibility toggled to: \(self.showBalance)")
    }

    // MARK: - Navigation Methods (AC: #5)

    /// Shows account detail for the selected account.
    /// - Parameter account: The account to show details for
    func showAccountDetail(_ account: Account) {
        Logger.home.debug("Navigate to account detail: \(account.id)")
        coordinator?.navigateToAccountDetail(accountId: account.id)
    }

    /// Shows the notifications list.
    func showNotifications() {
        Logger.home.debug("Navigate to notifications")
        coordinator?.push(.notifications)
    }

    /// Shows transaction detail for the selected transaction.
    /// - Parameter transaction: The transaction to show details for
    func showTransactionDetail(_ transaction: Transaction) {
        Logger.home.debug("Navigate to transaction detail: \(transaction.id)")
        coordinator?.navigateToTransactionDetail(transactionId: transaction.id)
    }

    /// Navigates to the Transfer tab.
    func navigateToTransfer() {
        Logger.home.debug("Navigate to Transfer tab")
        coordinator?.navigateToTransfer()
    }

    /// Navigates to the Cards tab.
    func navigateToCards() {
        Logger.home.debug("Navigate to Cards tab")
        coordinator?.navigateToCards()
    }

    /// Navigates to the More tab.
    func navigateToMore() {
        Logger.home.debug("Navigate to More tab")
        coordinator?.navigateToMore()
    }
}

// MARK: - UserDefaults Extension

private extension UserDefaults {
    /// Checks if a key exists in UserDefaults.
    func contains(key: String) -> Bool {
        return object(forKey: key) != nil
    }
}
