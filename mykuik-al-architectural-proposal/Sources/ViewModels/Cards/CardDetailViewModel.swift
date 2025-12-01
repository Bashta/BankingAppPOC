//  CardDetailViewModel.swift - Stub for Story 5.2
import Foundation
import Combine

final class CardDetailViewModel: ObservableObject {
    let cardId: String
    private let cardService: CardServiceProtocol
    private weak var coordinator: CardsCoordinator?

    init(cardId: String, cardService: CardServiceProtocol, coordinator: CardsCoordinator) {
        self.cardId = cardId
        self.cardService = cardService
        self.coordinator = coordinator
    }
}
