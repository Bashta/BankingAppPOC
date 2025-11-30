//
//  TransactionHistoryViewModel.swift
//  BankingApp
//
//  ViewModel for transaction history with pagination, search, and filtering.
//  Story 3.3: Implement Transaction History with Search and Filtering
//

import Foundation
import Combine
import OSLog

final class TransactionHistoryViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published var transactions: [Transaction] = []
    @Published var isLoading = false
    @Published var isLoadingMore = false
    @Published var isRefreshing = false
    @Published var error: Error?
    @Published var searchQuery: String = ""
    @Published var selectedCategories: Set<TransactionCategory> = []
    @Published var dateRange: (start: Date, end: Date)?
    @Published var currentPage = 1
    @Published var hasMorePages = true
    @Published var showingFilterSheet = false

    // MARK: - Properties

    let accountId: String

    var hasActiveFilters: Bool {
        !selectedCategories.isEmpty || dateRange != nil
    }

    // MARK: - Dependencies

    private let transactionService: TransactionServiceProtocol
    weak var coordinator: AccountsCoordinator?
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    init(
        accountId: String,
        transactionService: TransactionServiceProtocol,
        coordinator: AccountsCoordinator
    ) {
        self.accountId = accountId
        self.transactionService = transactionService
        self.coordinator = coordinator
        setupSearchDebounce()
    }

    // MARK: - Private Methods

    private func setupSearchDebounce() {
        $searchQuery
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .removeDuplicates()
            .sink { [weak self] query in
                guard let self = self else { return }
                Task { await self.performSearch(query: query) }
            }
            .store(in: &cancellables)
    }

    @MainActor
    private func performSearch(query: String) async {
        // If query is empty, reload all data
        if query.isEmpty {
            await loadData()
            return
        }

        isLoading = true
        error = nil
        defer { isLoading = false }

        do {
            let results = try await transactionService.searchTransactions(
                accountId: accountId,
                query: query
            )
            transactions = results
            hasMorePages = false // Search returns all matching results

            Logger.accounts.debug("Search '\(query)' returned \(results.count) results")
        } catch {
            self.error = error
            Logger.accounts.error("Search failed: \(error.localizedDescription)")
        }
    }

    // MARK: - Public Methods

    @MainActor
    func loadData() async {
        isLoading = true
        error = nil
        currentPage = 1
        defer { isLoading = false }

        do {
            let page = try await transactionService.fetchTransactions(
                accountId: accountId,
                page: 1,
                limit: 20
            )
            transactions = page.transactions
            currentPage = page.currentPage
            hasMorePages = page.currentPage < page.totalPages

            Logger.accounts.debug("Loaded \(page.transactions.count) transactions, hasMore: \(self.hasMorePages)")
        } catch {
            self.error = error
            Logger.accounts.error("Failed to load transactions: \(error.localizedDescription)")
        }
    }

    @MainActor
    func loadMore() async {
        guard !isLoadingMore && hasMorePages else { return }

        isLoadingMore = true
        defer { isLoadingMore = false }

        do {
            let page = try await transactionService.fetchTransactions(
                accountId: accountId,
                page: currentPage + 1,
                limit: 20
            )
            transactions.append(contentsOf: page.transactions)
            currentPage = page.currentPage
            hasMorePages = page.currentPage < page.totalPages

            Logger.accounts.debug("Loaded page \(self.currentPage), total: \(self.transactions.count)")
        } catch {
            Logger.accounts.error("Failed to load more: \(error.localizedDescription)")
        }
    }

    @MainActor
    func refresh() async {
        isRefreshing = true
        defer { isRefreshing = false }

        currentPage = 1
        do {
            let page = try await transactionService.fetchTransactions(
                accountId: accountId,
                page: 1,
                limit: 20
            )
            transactions = page.transactions
            currentPage = page.currentPage
            hasMorePages = page.currentPage < page.totalPages
            error = nil

            Logger.accounts.debug("Refreshed transactions, count: \(page.transactions.count)")
        } catch {
            self.error = error
            Logger.accounts.error("Refresh failed: \(error.localizedDescription)")
        }
    }

    @MainActor
    func applyFilters() async {
        isLoading = true
        error = nil
        showingFilterSheet = false
        defer { isLoading = false }

        do {
            // Convert dateRange to tuple format for service
            let dateRangeTuple: (Date, Date)?
            if let range = dateRange {
                dateRangeTuple = (range.start, range.end)
            } else {
                dateRangeTuple = nil
            }

            let results = try await transactionService.filterTransactions(
                accountId: accountId,
                dateRange: dateRangeTuple,
                categories: selectedCategories
            )
            transactions = results
            hasMorePages = false // Filtered results are complete

            Logger.accounts.debug("Filter applied, \(results.count) results")
        } catch {
            self.error = error
            Logger.accounts.error("Filter failed: \(error.localizedDescription)")
        }
    }

    func clearFilters() {
        selectedCategories.removeAll()
        dateRange = nil
        showingFilterSheet = false
        Task { await loadData() }
    }

    func showTransactionDetail(_ transaction: Transaction) {
        coordinator?.push(.transactionDetail(transactionId: transaction.id))
    }

    func toggleFilterSheet() {
        showingFilterSheet.toggle()
    }
}
