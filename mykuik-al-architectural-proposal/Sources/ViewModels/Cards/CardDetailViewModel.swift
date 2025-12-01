//
//  CardDetailViewModel.swift
//  BankingApp
//
//  ViewModel for Card Detail View - manages card information,
//  linked account, recent transactions, and navigation to card operations.
//  Story 5.2: Implement Card Detail View
//

import Foundation
import Combine
import OSLog

final class CardDetailViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published var card: Card?
    @Published var linkedAccount: Account?
    @Published var recentTransactions: [Transaction] = []
    @Published var isLoading = false
    @Published var isRefreshing = false
    @Published var error: Error?

    // MARK: - Properties

    let cardId: String

    // MARK: - Dependencies

    private let cardService: CardServiceProtocol
    private let accountService: AccountServiceProtocol
    private let transactionService: TransactionServiceProtocol
    weak var coordinator: CardsCoordinator?

    // MARK: - Initialization

    init(
        cardId: String,
        cardService: CardServiceProtocol,
        accountService: AccountServiceProtocol,
        transactionService: TransactionServiceProtocol,
        coordinator: CardsCoordinator?
    ) {
        self.cardId = cardId
        self.cardService = cardService
        self.accountService = accountService
        self.transactionService = transactionService
        self.coordinator = coordinator
    }

    // MARK: - Public Methods

    @MainActor
    func loadData() async {
        isLoading = true
        error = nil
        defer { isLoading = false }

        do {
            // Fetch card first (needed for linkedAccountId)
            let fetchedCard = try await cardService.fetchCard(id: cardId)
            self.card = fetchedCard

            Logger.cards.debug("Loaded card: \(self.cardId), accountId: \(fetchedCard.accountId)")

            // Parallel fetch: linked account and transactions
            async let accountTask = fetchLinkedAccount(accountId: fetchedCard.accountId)
            async let transactionsTask = fetchTransactions(accountId: fetchedCard.accountId)

            let (account, transactions) = await (accountTask, transactionsTask)
            self.linkedAccount = account
            self.recentTransactions = transactions

            Logger.cards.debug("Card detail loaded successfully for: \(self.cardId)")
        } catch {
            self.error = error
            Logger.cards.error("Failed to load card detail for \(self.cardId): \(error.localizedDescription)")
        }
    }

    @MainActor
    func refresh() async {
        isRefreshing = true
        defer { isRefreshing = false }

        // Clear error before refresh
        error = nil

        do {
            // Fetch card first
            let fetchedCard = try await cardService.fetchCard(id: cardId)
            self.card = fetchedCard

            // Parallel fetch: linked account and transactions
            async let accountTask = fetchLinkedAccount(accountId: fetchedCard.accountId)
            async let transactionsTask = fetchTransactions(accountId: fetchedCard.accountId)

            let (account, transactions) = await (accountTask, transactionsTask)
            self.linkedAccount = account
            self.recentTransactions = transactions

            Logger.cards.debug("Card detail refreshed for: \(self.cardId)")
        } catch {
            self.error = error
            Logger.cards.error("Failed to refresh card detail for \(self.cardId): \(error.localizedDescription)")
        }
    }

    // MARK: - Navigation Methods

    func showSettings() {
        Logger.cards.debug("Navigating to card settings: \(self.cardId)")
        coordinator?.push(.settings(cardId: cardId))
    }

    func showLimits() {
        Logger.cards.debug("Navigating to card limits: \(self.cardId)")
        coordinator?.push(.limits(cardId: cardId))
    }

    func showTransactionHistory() {
        guard let accountId = card?.accountId else {
            Logger.cards.warning("Cannot show transaction history: card not loaded")
            return
        }
        Logger.cards.debug("Navigating to card transactions for account: \(accountId)")
        // Navigate to account transactions since card transactions are associated with account
        coordinator?.navigateToAccountTransactions(accountId: accountId)
    }

    func activateCard() {
        guard card?.status == .pendingActivation || card?.status == .pending else {
            Logger.cards.warning("Cannot activate card: status is not pending activation")
            return
        }
        Logger.cards.debug("Navigating to card activation: \(self.cardId)")
        coordinator?.push(.activate(cardId: cardId))
    }

    func blockCard() {
        guard card?.status == .active else {
            Logger.cards.warning("Cannot block card: status is not active")
            return
        }
        Logger.cards.debug("Navigating to block card: \(self.cardId)")
        coordinator?.push(.block(cardId: cardId))
    }

    // MARK: - Computed Properties

    /// Determines if the card can be activated
    var canActivate: Bool {
        guard let status = card?.status else { return false }
        return status == .pendingActivation || status == .pending
    }

    /// Determines if the card can be blocked
    var canBlock: Bool {
        guard let status = card?.status else { return false }
        return status == .active
    }

    /// Determines if the card is blocked and may need unblocking
    var isBlocked: Bool {
        guard let status = card?.status else { return false }
        return status == .blocked
    }

    /// Determines if the card is in a terminal state (expired/cancelled)
    var isTerminalState: Bool {
        guard let status = card?.status else { return false }
        return status == .expired || status == .cancelled
    }

    // MARK: - Private Methods

    private func fetchLinkedAccount(accountId: String) async -> Account? {
        do {
            let account = try await accountService.fetchAccount(id: accountId)
            Logger.cards.debug("Fetched linked account: \(accountId)")
            return account
        } catch {
            // Graceful degradation - show card without account section
            Logger.cards.warning("Failed to fetch linked account \(accountId): \(error.localizedDescription)")
            return nil
        }
    }

    private func fetchTransactions(accountId: String) async -> [Transaction] {
        do {
            // Fetch recent transactions for the linked account (limit to 5)
            let page = try await transactionService.fetchTransactions(
                accountId: accountId,
                page: 1,
                limit: 5
            )
            Logger.cards.debug("Fetched \(page.transactions.count) recent transactions for card")
            return page.transactions
        } catch {
            // Graceful degradation - show card without transactions
            Logger.cards.warning("Failed to fetch card transactions: \(error.localizedDescription)")
            return []
        }
    }
}
