import Foundation
import Combine
import OSLog

// MARK: - CardsListViewModel

/// ViewModel managing the cards list state, loading, and navigation delegation.
final class CardsListViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published var cards: [Card] = []
    @Published var isLoading = false
    @Published var isRefreshing = false
    @Published var error: Error?

    // MARK: - Dependencies

    private let cardService: CardServiceProtocol
    weak var coordinator: CardsCoordinator?

    // MARK: - Initialization

    init(cardService: CardServiceProtocol, coordinator: CardsCoordinator?) {
        self.cardService = cardService
        self.coordinator = coordinator
    }

    // MARK: - Public Methods

    /// Loads all cards from the service.
    /// Sets isLoading during fetch and stores results or error.
    @MainActor
    func loadData() async {
        // Skip if already loaded (ViewModel is cached, so this prevents unnecessary re-fetches)
        guard cards.isEmpty else { return }

        isLoading = true
        error = nil
        defer { isLoading = false }

        do {
            cards = try await cardService.fetchCards()
            Logger.cards.debug("Loaded \(self.cards.count) cards")
        } catch {
            self.error = error
            Logger.cards.error("Failed to load cards: \(error.localizedDescription)")
        }
    }

    /// Refreshes the card list (pull-to-refresh).
    /// Sets isRefreshing during fetch.
    @MainActor
    func refresh() async {
        isRefreshing = true
        defer { isRefreshing = false }

        do {
            cards = try await cardService.fetchCards()
            Logger.cards.debug("Refreshed cards: \(self.cards.count) cards")
        } catch {
            self.error = error
            Logger.cards.error("Failed to refresh cards: \(error.localizedDescription)")
        }
    }

    /// Navigates to card detail screen.
    /// - Parameter card: The card to show details for.
    func showCardDetail(_ card: Card) {
        Logger.cards.debug("Navigating to card detail: \(card.id)")
        coordinator?.push(.detail(cardId: card.id))
    }
}
