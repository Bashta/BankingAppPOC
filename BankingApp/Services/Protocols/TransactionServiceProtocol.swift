import Foundation

protocol TransactionServiceProtocol {
    func fetchTransactions(accountId: String, page: Int, limit: Int) async throws -> TransactionPage
    func fetchTransaction(id: String) async throws -> Transaction
    func searchTransactions(accountId: String, query: String) async throws -> [Transaction]
    func filterTransactions(accountId: String, dateRange: (Date, Date)?, categories: Set<TransactionCategory>) async throws -> [Transaction]
}
