import Foundation

// MARK: - TransferDestination Enum

enum TransferDestination: Hashable, Codable {
    case internalAccount(accountId: String)
    case beneficiary(beneficiaryId: String)
}

// MARK: - TransferStatus Enum

enum TransferStatus: String, Codable {
    case initiated
    case pending
    case completed
    case failed
    case cancelled
}

// MARK: - TransferType Enum

enum TransferType: String, Codable {
    case `internal`
    case external
    case international
}

// MARK: - Transfer Model

struct Transfer: Identifiable, Hashable, Codable {
    let id: String
    let sourceAccountId: String
    let destinationType: TransferDestination
    let amount: Decimal
    let currency: String
    let description: String
    let reference: String
    let status: TransferStatus
    let date: Date
    let type: TransferType
    let initiatedDate: Date?
    let completedDate: Date?
    let otpRequired: Bool
    let otpReference: OTPReference?
}

// MARK: - TransferRequest Model

struct TransferRequest: Hashable, Codable {
    let sourceAccountId: String
    let destinationType: TransferDestination
    let amount: Decimal
    let currency: String
    let description: String
}
