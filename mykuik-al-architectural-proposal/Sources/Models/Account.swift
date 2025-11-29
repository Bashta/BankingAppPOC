import Foundation

// MARK: - AccountType Enum

enum AccountType: String, Codable, CaseIterable {
    case checking = "CHECKING"
    case savings = "SAVINGS"
    case deposit = "DEPOSIT"
    case loan = "LOAN"
}

// MARK: - Account Model

struct Account: Identifiable, Hashable, Codable {
    let id: String
    let accountNumber: String
    let accountType: AccountType
    let currency: String
    let balance: Decimal
    let availableBalance: Decimal
    let accountName: String
    let iban: String?
    let isDefault: Bool
}

// MARK: - AccountUpdates Model

struct AccountUpdates: Hashable, Codable {
    let accountName: String?
    let isDefault: Bool?
}
