import Foundation

protocol CardServiceProtocol {
    func fetchCards() async throws -> [Card]
    func fetchCard(id: String) async throws -> Card
    func activateCard(id: String, lastFourDigits: String) async throws -> Card
    func blockCard(id: String, reason: BlockReason) async throws -> Card
    func unblockCard(id: String) async throws -> Card
    func updateLimits(id: String, limits: CardLimits) async throws -> Card
    func requestPINChange(id: String, otpCode: String) async throws
}
