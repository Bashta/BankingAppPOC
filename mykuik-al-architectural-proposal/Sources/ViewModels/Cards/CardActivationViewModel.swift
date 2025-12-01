//
//  CardActivationViewModel.swift
//  BankingApp
//
//  ViewModel for Card Activation View - manages input validation,
//  activation API calls, and navigation back to card detail.
//  Story 5.3: Implement Card Activation Flow
//

import Foundation
import Combine
import OSLog

final class CardActivationViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published var lastFourDigits: String = ""
    @Published var isActivating = false
    @Published var error: Error?
    @Published var isSuccess = false

    // MARK: - Properties

    let cardId: String

    // MARK: - Dependencies

    private let cardService: CardServiceProtocol
    weak var coordinator: CardsCoordinator?

    // MARK: - Computed Properties

    /// Validates that input is exactly 4 numeric digits
    var isValidInput: Bool {
        lastFourDigits.count == 4 && lastFourDigits.allSatisfy { $0.isNumber }
    }

    // MARK: - Initialization

    init(
        cardId: String,
        cardService: CardServiceProtocol,
        coordinator: CardsCoordinator
    ) {
        self.cardId = cardId
        self.cardService = cardService
        self.coordinator = coordinator

        Logger.cards.debug("CardActivationViewModel initialized for card: \(cardId)")
    }

    // MARK: - Public Methods

    /// Activates the card with the entered last 4 digits
    @MainActor
    func activateCard() async {
        guard isValidInput else {
            error = CardError.invalidLastFourDigits
            Logger.cards.warning("Card activation failed: invalid input - \(self.lastFourDigits.count) digits entered")
            return
        }

        isActivating = true
        error = nil
        defer { isActivating = false }

        Logger.cards.debug("Attempting to activate card: \(self.cardId)")

        do {
            let _ = try await cardService.activateCard(id: cardId, lastFourDigits: lastFourDigits)
            isSuccess = true
            Logger.cards.info("Card activated successfully: \(self.cardId)")

            // Auto-navigate back after brief delay to show success state
            try? await Task.sleep(nanoseconds: 1_500_000_000) // 1.5 seconds
            coordinator?.pop()
        } catch {
            self.error = error
            Logger.cards.error("Card activation failed for \(self.cardId): \(error.localizedDescription)")
        }
    }

    /// Clears any existing error
    func clearError() {
        error = nil
    }

    /// Updates the last four digits with validation (limits to 4 numeric characters)
    func updateLastFourDigits(_ newValue: String) {
        // Filter to only numeric characters and limit to 4
        let filtered = String(newValue.filter { $0.isNumber }.prefix(4))
        if lastFourDigits != filtered {
            lastFourDigits = filtered
            clearError()
        }
    }

    /// Cancels the activation and navigates back
    func cancel() {
        Logger.cards.debug("Card activation cancelled for: \(self.cardId)")
        coordinator?.pop()
    }
}
