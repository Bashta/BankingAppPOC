import Foundation

protocol CardServiceProtocol {
    func fetchCards() async throws -> [Card]
    func fetchCard(id: String) async throws -> Card
    func activateCard(id: String, lastFourDigits: String) async throws -> Card
    func blockCard(id: String, reason: BlockReason) async throws -> Card
    func unblockCard(id: String) async throws -> Card
    func updateLimits(id: String, limits: CardLimits) async throws -> Card
    func requestPINChange(cardId: String) async throws -> OTPReference
    func verifyPINChange(cardId: String, otpCode: String) async throws -> Bool
}
