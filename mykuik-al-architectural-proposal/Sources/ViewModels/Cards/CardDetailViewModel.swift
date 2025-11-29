//  CardDetailViewModel.swift - Stub for compilation
import Foundation
import Combine

final class CardDetailViewModel: ObservableObject {
    private let cardId: String
    private let cardService: CardServiceProtocol
    private weak var coordinator: CardsCoordinator?
    init(cardId: String, cardService: CardServiceProtocol, coordinator: CardsCoordinator) {
        self.cardId = cardId
        self.cardService = cardService
        self.coordinator = coordinator
    }
}
