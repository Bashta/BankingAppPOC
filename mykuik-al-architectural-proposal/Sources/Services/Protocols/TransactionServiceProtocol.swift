import Foundation

protocol TransactionServiceProtocol {
    func fetchTransactions(accountId: String, page: Int, limit: Int) async throws -> TransactionPage
    func fetchTransaction(id: String) async throws -> Transaction
    func searchTransactions(accountId: String, query: String) async throws -> [Transaction]
    func filterTransactions(accountId: String, dateRange: (Date, Date)?, categories: Set<TransactionCategory>) async throws -> [Transaction]

    /// Fetches recent transactions across all accounts for dashboard display.
    /// - Parameter limit: Maximum number of transactions to return
    /// - Returns: Array of recent transactions sorted by date (newest first)
    func fetchRecentTransactions(limit: Int) async throws -> [Transaction]
}
