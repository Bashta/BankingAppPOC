import Foundation

// MARK: - TransactionType Enum

enum TransactionType: String, Codable {
    case credit = "CREDIT"
    case debit = "DEBIT"
}

// MARK: - TransactionCategory Enum

enum TransactionCategory: String, Codable, CaseIterable {
    case transfer
    case payment
    case withdrawal
    case deposit
    case fee
    case interest
    case purchase
    case refund
    case salary
    case other
}

// MARK: - TransactionStatus Enum

enum TransactionStatus: String, Codable {
    case pending
    case completed
    case failed
    case cancelled
}

// MARK: - Transaction Model

struct Transaction: Identifiable, Hashable, Codable {
    let id: String
    let accountId: String
    let type: TransactionType
    let amount: Decimal
    let currency: String
    let description: String
    let merchantName: String?
    let category: TransactionCategory
    let date: Date
    let status: TransactionStatus
    let reference: String?
    let balance: Decimal?
}

// MARK: - TransactionPage Model

struct TransactionPage: Hashable, Codable {
    let transactions: [Transaction]
    let currentPage: Int
    let totalPages: Int
    let totalItems: Int
}
