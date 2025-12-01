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

    /// Whether this block reason allows unblocking.
    /// Only cards blocked for suspicious activity can be unblocked.
    /// Cards blocked as lost, stolen, or damaged require a replacement card.
    var canUnblock: Bool {
        switch self {
        case .suspicious:
            return true
        case .lost, .stolen, .damaged:
            return false
        }
    }

    /// Short display name for UI selection
    var shortName: String {
        switch self {
        case .lost:
            return "Lost"
        case .stolen:
            return "Stolen"
        case .damaged:
            return "Damaged"
        case .suspicious:
            return "Suspicious Activity"
        }
    }

    /// Description for the reason selection UI
    var reasonDescription: String {
        switch self {
        case .lost:
            return "I can't find my card"
        case .stolen:
            return "My card was stolen"
        case .damaged:
            return "My card is physically damaged"
        case .suspicious:
            return "I noticed suspicious transactions"
        }
    }

    /// SF Symbol icon for the reason
    var iconName: String {
        switch self {
        case .lost:
            return "location.slash.fill"
        case .stolen:
            return "hand.raised.slash.fill"
        case .damaged:
            return "exclamationmark.triangle.fill"
        case .suspicious:
            return "questionmark.circle.fill"
        }
    }
}

// MARK: - CardLimits Model

struct CardLimits: Hashable, Codable {
    let dailyPurchase: Decimal
    let dailyWithdrawal: Decimal
    let onlineTransaction: Decimal
    let contactless: Decimal

    // MARK: - Validation Constants

    static let maxDailyPurchase: Decimal = 10000
    static let maxDailyWithdrawal: Decimal = 2000
    static let maxOnlineTransaction: Decimal = 5000
    static let maxContactless: Decimal = 500
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
}
