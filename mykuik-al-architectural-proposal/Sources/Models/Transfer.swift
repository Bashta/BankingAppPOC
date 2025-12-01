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

    var displayName: String {
        switch self {
        case .initiated: return "Initiated"
        case .pending: return "Pending"
        case .completed: return "Completed"
        case .failed: return "Failed"
        case .cancelled: return "Cancelled"
        }
    }
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

    /// Display name for the destination (account name or beneficiary name)
    let destinationName: String

    /// Source account name for display purposes
    let sourceAccountName: String?
}

// MARK: - TransferRequest Model

struct TransferRequest: Hashable, Codable, Identifiable {
    let id: String
    let type: TransferType
    let sourceAccountId: String
    let destinationAccountId: String?
    let beneficiaryId: String?
    let amount: Decimal
    let currency: String
    let description: String?

    init(
        type: TransferType,
        sourceAccountId: String,
        destinationAccountId: String? = nil,
        beneficiaryId: String? = nil,
        amount: Decimal,
        currency: String,
        description: String? = nil
    ) {
        self.id = UUID().uuidString
        self.type = type
        self.sourceAccountId = sourceAccountId
        self.destinationAccountId = destinationAccountId
        self.beneficiaryId = beneficiaryId
        self.amount = amount
        self.currency = currency
        self.description = description
    }
}
