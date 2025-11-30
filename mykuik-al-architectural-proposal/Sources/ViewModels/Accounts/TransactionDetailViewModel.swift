//
//  TransactionDetailViewModel.swift
//  BankingApp
//
//  ViewModel for transaction detail screen - displays comprehensive transaction information.
//  Story 3.4: Implement Transaction Detail View
//

import Foundation
import Combine
import OSLog

final class TransactionDetailViewModel: ObservableObject {

    // MARK: - Published Properties

    /// The transaction being displayed (nil until loaded)
    @Published var transaction: Transaction?

    /// Loading state for initial fetch
    @Published var isLoading = false

    /// Refreshing state for pull-to-refresh
    @Published var isRefreshing = false

    /// Error state for fetch failures
    @Published var error: Error?

    // MARK: - Properties

    /// The ID of the transaction to fetch
    let transactionId: String

    // MARK: - Dependencies

    private let transactionService: TransactionServiceProtocol

    /// Weak reference to coordinator to prevent retain cycle
    weak var coordinator: AccountsCoordinator?

    // MARK: - Initialization

    /// Creates a TransactionDetailViewModel with required dependencies.
    ///
    /// - Parameters:
    ///   - transactionId: The ID of the transaction to display
    ///   - transactionService: Service for fetching transaction data
    ///   - coordinator: Weak reference to AccountsCoordinator for navigation
    init(
        transactionId: String,
        transactionService: TransactionServiceProtocol,
        coordinator: AccountsCoordinator?
    ) {
        self.transactionId = transactionId
        self.transactionService = transactionService
        self.coordinator = coordinator
    }

    // MARK: - Public Methods

    /// Loads the transaction details from the service.
    ///
    /// Sets `isLoading = true` before fetch, resets error, and updates `transaction` on success.
    /// Uses defer to ensure `isLoading = false` is called even on error.
    @MainActor
    func loadData() async {
        isLoading = true
        error = nil
        defer { isLoading = false }

        do {
            transaction = try await transactionService.fetchTransaction(id: transactionId)

            #if DEBUG
            Logger.accounts.debug("Loaded transaction: \(self.transactionId)")
            #endif
        } catch {
            self.error = error
            Logger.accounts.error("Failed to load transaction \(self.transactionId): \(error.localizedDescription)")
        }
    }

    /// Refreshes the transaction data (pull-to-refresh).
    ///
    /// Sets `isRefreshing = true` before fetch, clears error on success.
    /// Useful for checking updated transaction status (pending → completed).
    @MainActor
    func refresh() async {
        isRefreshing = true
        defer { isRefreshing = false }

        do {
            transaction = try await transactionService.fetchTransaction(id: transactionId)
            error = nil

            #if DEBUG
            Logger.accounts.debug("Refreshed transaction: \(self.transactionId)")
            #endif
        } catch {
            self.error = error
            Logger.accounts.error("Failed to refresh transaction \(self.transactionId): \(error.localizedDescription)")
        }
    }
}
