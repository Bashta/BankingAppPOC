//
//  CardsViewFactory.swift
//  BankingApp
//
//  View factory for Cards feature that creates View+ViewModel pairs
//  for all card management screens.
//

import SwiftUI

final class CardsViewFactory {
    private let dependencyContainer: DependencyContainer

    init(dependencyContainer: DependencyContainer) {
        self.dependencyContainer = dependencyContainer
    }

    // MARK: - Cards Feature Views

    func makeCardsListView(coordinator: CardsCoordinator) -> some View {
        let viewModel = CardsListViewModel(
            cardService: dependencyContainer.cardService,
            coordinator: coordinator
        )
        return CardsListView(viewModel: viewModel)
    }

    func makeCardDetailView(cardId: String, coordinator: CardsCoordinator) -> some View {
        let viewModel = CardDetailViewModel(
            cardId: cardId,
            cardService: dependencyContainer.cardService,
            coordinator: coordinator
        )
        return CardDetailView(viewModel: viewModel)
    }

    func makeCardActivationView(cardId: String, coordinator: CardsCoordinator) -> some View {
        let viewModel = CardActivationViewModel(
            cardId: cardId,
            cardService: dependencyContainer.cardService,
            coordinator: coordinator
        )
        return CardActivationView(viewModel: viewModel)
    }

    func makeActivateCardView(cardId: String, coordinator: CardsCoordinator) -> some View {
        makeCardActivationView(cardId: cardId, coordinator: coordinator)
    }

    func makeBlockCardView(cardId: String, coordinator: CardsCoordinator) -> some View {
        let viewModel = BlockCardViewModel(
            cardId: cardId,
            cardService: dependencyContainer.cardService,
            coordinator: coordinator
        )
        return BlockCardView(viewModel: viewModel)
    }

    func makeCardBlockView(cardId: String, coordinator: CardsCoordinator) -> some View {
        makeBlockCardView(cardId: cardId, coordinator: coordinator)
    }

    func makeCardLimitsView(cardId: String, coordinator: CardsCoordinator) -> some View {
        let viewModel = CardLimitsViewModel(
            cardId: cardId,
            cardService: dependencyContainer.cardService,
            coordinator: coordinator
        )
        return CardLimitsView(viewModel: viewModel)
    }

    func makeCardPINChangeView(cardId: String, coordinator: CardsCoordinator) -> some View {
        let viewModel = CardPINChangeViewModel(
            cardId: cardId,
            cardService: dependencyContainer.cardService,
            coordinator: coordinator
        )
        return CardPINChangeView(viewModel: viewModel)
    }

    func makeChangePINView(cardId: String, coordinator: CardsCoordinator) -> some View {
        makeCardPINChangeView(cardId: cardId, coordinator: coordinator)
    }

    func makeCardSettingsView(cardId: String, coordinator: CardsCoordinator) -> some View {
        let viewModel = CardSettingsViewModel(
            cardId: cardId,
            cardService: dependencyContainer.cardService,
            coordinator: coordinator
        )
        return CardSettingsView(viewModel: viewModel)
    }
}
