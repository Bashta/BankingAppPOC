import Foundation

// MARK: - CardType Enum

enum CardType: String, Codable {
    case debit
    case credit
    case prepaid
}

// MARK: - CardBrand Enum

enum CardBrand: String, Codable {
    case visa
    case mastercard
    case amex
}

// MARK: - CardStatus Enum

enum CardStatus: String, Codable {
    case active
    case inactive
    case blocked
    case pendingActivation
    case pending // Alias for pendingActivation
    case expired
    case cancelled
}

// MARK: - BlockReason Enum

enum BlockReason: String, Codable {
    case lost
    case stolen
    case damaged
    case suspicious

    var displayName: String {
        switch self {
        case .lost:
            return "Card reported lost"
        case .stolen:
            return "Card reported stolen"
        case .damaged:
            return "Card damaged"
        case .suspicious:
            return "Suspicious activity detected"
        }
    }
}

// MARK: - CardLimits Model

struct CardLimits: Hashable, Codable {
    let dailyPurchase: Decimal
    let dailyWithdrawal: Decimal
    let onlineTransaction: Decimal
    let contactless: Decimal
}

// MARK: - Card Model

struct Card: Identifiable, Hashable, Codable {
    let id: String
    let accountId: String
    let cardNumber: String
    let cardType: CardType
    let cardBrand: CardBrand
    let cardholderName: String
    let expiryMonth: Int
    let expiryYear: Int
    let cvv: String
    let status: CardStatus
    let limits: CardLimits
    let activatedDate: Date?
    let blockedDate: Date?
    let blockReason: BlockReason?

    var expiryDate: Date {
        var components = DateComponents()
        components.month = expiryMonth
        components.year = expiryYear
        components.day = 1
        return Calendar.current.date(from: components) ?? Date()
    }
}
