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

    // Cached ViewModels to prevent recreation on navigation state changes
    private var cachedCardsListViewModel: CardsListViewModel?
    private var cachedCardDetailViewModels: [String: CardDetailViewModel] = [:]
    private var cachedCardActivationViewModels: [String: CardActivationViewModel] = [:]
    private var cachedBlockCardViewModels: [String: BlockCardViewModel] = [:]
    private var cachedCardLimitsViewModels: [String: CardLimitsViewModel] = [:]
    private var cachedCardPINChangeViewModels: [String: CardPINChangeViewModel] = [:]
    private var cachedCardSettingsViewModels: [String: CardSettingsViewModel] = [:]

    init(dependencyContainer: DependencyContainer) {
        self.dependencyContainer = dependencyContainer
    }

    // MARK: - Cards Feature Views

    func makeCardsListView(coordinator: CardsCoordinator) -> some View {
        if cachedCardsListViewModel == nil {
            cachedCardsListViewModel = CardsListViewModel(
                cardService: dependencyContainer.cardService,
                coordinator: coordinator
            )
        }
        return CardsListView(viewModel: cachedCardsListViewModel!)
    }

    func makeCardDetailView(cardId: String, coordinator: CardsCoordinator) -> some View {
        if cachedCardDetailViewModels[cardId] == nil {
            cachedCardDetailViewModels[cardId] = CardDetailViewModel(
                cardId: cardId,
                cardService: dependencyContainer.cardService,
                accountService: dependencyContainer.accountService,
                transactionService: dependencyContainer.transactionService,
                coordinator: coordinator
            )
        }
        return CardDetailView(viewModel: cachedCardDetailViewModels[cardId]!)
    }

    func makeCardActivationView(cardId: String, coordinator: CardsCoordinator) -> some View {
        if cachedCardActivationViewModels[cardId] == nil {
            cachedCardActivationViewModels[cardId] = CardActivationViewModel(
                cardId: cardId,
                cardService: dependencyContainer.cardService,
                coordinator: coordinator
            )
        }
        return CardActivationView(viewModel: cachedCardActivationViewModels[cardId]!)
    }

    func makeActivateCardView(cardId: String, coordinator: CardsCoordinator) -> some View {
        makeCardActivationView(cardId: cardId, coordinator: coordinator)
    }

    func makeBlockCardView(
        cardId: String,
        currentStatus: CardStatus,
        blockReason: BlockReason?,
        coordinator: CardsCoordinator
    ) -> some View {
        // Use a cache key that includes status to handle mode changes
        let cacheKey = "\(cardId)-\(currentStatus.rawValue)"
        if cachedBlockCardViewModels[cacheKey] == nil {
            cachedBlockCardViewModels[cacheKey] = BlockCardViewModel(
                cardId: cardId,
                initialStatus: currentStatus,
                blockReason: blockReason,
                cardService: dependencyContainer.cardService,
                coordinator: coordinator
            )
        }
        return BlockCardView(viewModel: cachedBlockCardViewModels[cacheKey]!)
    }

    func makeCardLimitsView(cardId: String, coordinator: CardsCoordinator) -> some View {
        if cachedCardLimitsViewModels[cardId] == nil {
            cachedCardLimitsViewModels[cardId] = CardLimitsViewModel(
                cardId: cardId,
                cardService: dependencyContainer.cardService,
                coordinator: coordinator
            )
        }
        return CardLimitsView(viewModel: cachedCardLimitsViewModels[cardId]!)
    }

    func makeCardPINChangeView(cardId: String, coordinator: CardsCoordinator) -> some View {
        if cachedCardPINChangeViewModels[cardId] == nil {
            cachedCardPINChangeViewModels[cardId] = CardPINChangeViewModel(
                cardId: cardId,
                cardService: dependencyContainer.cardService,
                coordinator: coordinator
            )
        }
        return CardPINChangeView(viewModel: cachedCardPINChangeViewModels[cardId]!)
    }

    func makeChangePINView(cardId: String, coordinator: CardsCoordinator) -> some View {
        makeCardPINChangeView(cardId: cardId, coordinator: coordinator)
    }

    func makeCardSettingsView(cardId: String, coordinator: CardsCoordinator) -> some View {
        if cachedCardSettingsViewModels[cardId] == nil {
            cachedCardSettingsViewModels[cardId] = CardSettingsViewModel(
                cardId: cardId,
                cardService: dependencyContainer.cardService,
                coordinator: coordinator
            )
        }
        return CardSettingsView(viewModel: cachedCardSettingsViewModels[cardId]!)
    }
}
