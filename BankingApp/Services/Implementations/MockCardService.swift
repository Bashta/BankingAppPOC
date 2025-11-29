import Foundation

final class MockCardService: CardServiceProtocol {
    private var cards: [Card] = [
        Card(
            id: "CARD001",
            accountId: "ACC001",
            cardNumber: "4532123456781234",
            cardType: .debit,
            cardBrand: .visa,
            cardholderName: "JOHN DOE",
            expiryMonth: 12,
            expiryYear: 2027,
            cvv: "123",
            status: .active,
            limits: CardLimits(
                dailyPurchase: 5000.00,
                dailyWithdrawal: 2000.00,
                onlineTransaction: 3000.00,
                contactless: 500.00
            ),
            activatedDate: Date().addingTimeInterval(-86400 * 365), // 1 year ago
            blockedDate: nil,
            blockReason: nil
        ),
        Card(
            id: "CARD002",
            accountId: "ACC001",
            cardNumber: "5412345678901234",
            cardType: .credit,
            cardBrand: .mastercard,
            cardholderName: "JOHN DOE",
            expiryMonth: 8,
            expiryYear: 2026,
            cvv: "456",
            status: .active,
            limits: CardLimits(
                dailyPurchase: 10000.00,
                dailyWithdrawal: 1000.00,
                onlineTransaction: 5000.00,
                contactless: 300.00
            ),
            activatedDate: Date().addingTimeInterval(-86400 * 180), // 6 months ago
            blockedDate: nil,
            blockReason: nil
        ),
        Card(
            id: "CARD003",
            accountId: "ACC002",
            cardNumber: "4916123456789012",
            cardType: .debit,
            cardBrand: .visa,
            cardholderName: "JOHN DOE",
            expiryMonth: 3,
            expiryYear: 2028,
            cvv: "789",
            status: .pending,
            limits: CardLimits(
                dailyPurchase: 3000.00,
                dailyWithdrawal: 1500.00,
                onlineTransaction: 2000.00,
                contactless: 200.00
            ),
            activatedDate: nil,
            blockedDate: nil,
            blockReason: nil
        )
    ]

    func fetchCards() async throws -> [Card] {
        try await Task.sleep(nanoseconds: UInt64.random(in: 300_000_000...500_000_000))
        return cards
    }

    func fetchCard(id: String) async throws -> Card {
        try await Task.sleep(nanoseconds: UInt64.random(in: 300_000_000...500_000_000))
        guard let card = cards.first(where: { $0.id == id }) else {
            throw CardError.cardNotFound
        }
        return card
    }

    func activateCard(id: String, lastFourDigits: String) async throws -> Card {
        try await Task.sleep(nanoseconds: UInt64.random(in: 300_000_000...500_000_000))

        guard let index = cards.firstIndex(where: { $0.id == id }) else {
            throw CardError.cardNotFound
        }

        let card = cards[index]

        guard card.status == .pending else {
            throw CardError.cardAlreadyActive
        }

        let cardLastFour = String(card.cardNumber.suffix(4))
        guard cardLastFour == lastFourDigits else {
            throw CardError.invalidLastFourDigits
        }

        let updatedCard = Card(
            id: card.id,
            accountId: card.accountId,
            cardNumber: card.cardNumber,
            cardType: card.cardType,
            cardBrand: card.cardBrand,
            cardholderName: card.cardholderName,
            expiryMonth: card.expiryMonth,
            expiryYear: card.expiryYear,
            cvv: card.cvv,
            status: .active,
            limits: card.limits,
            activatedDate: Date(),
            blockedDate: nil,
            blockReason: nil
        )
        cards[index] = updatedCard

        return updatedCard
    }

    func blockCard(id: String, reason: BlockReason) async throws -> Card {
        try await Task.sleep(nanoseconds: UInt64.random(in: 300_000_000...500_000_000))

        guard let index = cards.firstIndex(where: { $0.id == id }) else {
            throw CardError.cardNotFound
        }

        let card = cards[index]

        guard card.status != .blocked else {
            throw CardError.cardAlreadyBlocked
        }

        let updatedCard = Card(
            id: card.id,
            accountId: card.accountId,
            cardNumber: card.cardNumber,
            cardType: card.cardType,
            cardBrand: card.cardBrand,
            cardholderName: card.cardholderName,
            expiryMonth: card.expiryMonth,
            expiryYear: card.expiryYear,
            cvv: card.cvv,
            status: .blocked,
            limits: card.limits,
            activatedDate: card.activatedDate,
            blockedDate: Date(),
            blockReason: reason
        )
        cards[index] = updatedCard

        return updatedCard
    }

    func unblockCard(id: String) async throws -> Card {
        try await Task.sleep(nanoseconds: UInt64.random(in: 300_000_000...500_000_000))

        guard let index = cards.firstIndex(where: { $0.id == id }) else {
            throw CardError.cardNotFound
        }

        let card = cards[index]

        guard card.status == .blocked else {
            throw CardError.cardNotBlocked
        }

        let updatedCard = Card(
            id: card.id,
            accountId: card.accountId,
            cardNumber: card.cardNumber,
            cardType: card.cardType,
            cardBrand: card.cardBrand,
            cardholderName: card.cardholderName,
            expiryMonth: card.expiryMonth,
            expiryYear: card.expiryYear,
            cvv: card.cvv,
            status: .active,
            limits: card.limits,
            activatedDate: card.activatedDate,
            blockedDate: nil,
            blockReason: nil
        )
        cards[index] = updatedCard

        return updatedCard
    }

    func updateLimits(id: String, limits: CardLimits) async throws -> Card {
        try await Task.sleep(nanoseconds: UInt64.random(in: 300_000_000...500_000_000))

        guard let index = cards.firstIndex(where: { $0.id == id }) else {
            throw CardError.cardNotFound
        }

        let card = cards[index]
        let updatedCard = Card(
            id: card.id,
            accountId: card.accountId,
            cardNumber: card.cardNumber,
            cardType: card.cardType,
            cardBrand: card.cardBrand,
            cardholderName: card.cardholderName,
            expiryMonth: card.expiryMonth,
            expiryYear: card.expiryYear,
            cvv: card.cvv,
            status: card.status,
            limits: limits,
            activatedDate: card.activatedDate,
            blockedDate: card.blockedDate,
            blockReason: card.blockReason
        )
        cards[index] = updatedCard

        return updatedCard
    }

    func requestPINChange(id: String, otpCode: String) async throws {
        try await Task.sleep(nanoseconds: 500_000_000) // 500ms for OTP verification

        guard cards.contains(where: { $0.id == id }) else {
            throw CardError.cardNotFound
        }

        guard otpCode == "123456" else {
            throw CardError.invalidOTP
        }

        // PIN change request accepted (no actual PIN change in mock)
    }
}

enum CardError: Error {
    case cardNotFound
    case invalidLastFourDigits
    case cardAlreadyActive
    case cardAlreadyBlocked
    case cardNotBlocked
    case invalidOTP
}
