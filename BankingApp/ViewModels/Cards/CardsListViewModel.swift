//  CardsListViewModel.swift - Stub for compilation
import Foundation
import Combine

final class CardsListViewModel: ObservableObject {
    private let cardService: CardServiceProtocol
    private weak var coordinator: CardsCoordinator?
    init(cardService: CardServiceProtocol, coordinator: CardsCoordinator) {
        self.cardService = cardService
        self.coordinator = coordinator
    }
}
