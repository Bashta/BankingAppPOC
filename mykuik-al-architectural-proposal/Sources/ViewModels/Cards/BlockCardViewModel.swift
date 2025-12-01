//
//  BlockCardViewModel.swift
//  BankingApp
//
//  ViewModel for Block/Unblock Card View - manages reason selection,
//  confirmation dialogs, block/unblock API calls, and navigation.
//  Story 5.4: Implement Block/Unblock Card Flow
//

import Foundation
import Combine
import OSLog

final class BlockCardViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published var selectedReason: BlockReason?
    @Published var additionalNotes: String = ""
    @Published var isBlocking = false
    @Published var isUnblocking = false
    @Published var error: Error?
    @Published var showBlockConfirmation = false
    @Published var showUnblockConfirmation = false
    @Published var isSuccess = false

    // MARK: - Properties

    let cardId: String
    let initialStatus: CardStatus
    let blockReason: BlockReason?

    // MARK: - Dependencies

    private let cardService: CardServiceProtocol
    weak var coordinator: CardsCoordinator?

    // MARK: - Computed Properties

    /// Returns true if the card is in a state that can be blocked (active)
    var isBlockMode: Bool {
        initialStatus == .active
    }

    /// Returns true if the blocked card can be unblocked (only for suspicious activity)
    var canUnblock: Bool {
        guard !isBlockMode, let reason = blockReason else {
            return false
        }
        return reason.canUnblock
    }

    /// Validates that input is valid for the current mode
    var isValidInput: Bool {
        if isBlockMode {
            return selectedReason != nil
        } else {
            // Unblock mode doesn't require any input
            return true
        }
    }

    /// Returns appropriate warning message based on mode and reason
    var warningMessage: String {
        if isBlockMode {
            return "Blocking your card will prevent all transactions"
        } else if let reason = blockReason {
            return "Your card was blocked due to: \(reason.displayName)"
        } else {
            return "Your card is blocked"
        }
    }

    /// Returns true if any async operation is in progress
    var isLoading: Bool {
        isBlocking || isUnblocking
    }

    // MARK: - Initialization

    init(
        cardId: String,
        initialStatus: CardStatus,
        blockReason: BlockReason?,
        cardService: CardServiceProtocol,
        coordinator: CardsCoordinator
    ) {
        self.cardId = cardId
        self.initialStatus = initialStatus
        self.blockReason = blockReason
        self.cardService = cardService
        self.coordinator = coordinator

        Logger.cards.debug("BlockCardViewModel initialized for card: \(cardId), mode: \(initialStatus == .active ? "block" : "unblock")")
    }

    // MARK: - Block Methods

    /// Shows the block confirmation alert
    func showBlockAlert() {
        showBlockConfirmation = true
    }

    /// Dismisses the block confirmation alert
    func dismissBlockAlert() {
        showBlockConfirmation = false
    }

    /// Confirms and executes the block operation
    @MainActor
    func confirmBlock() async {
        guard let reason = selectedReason else {
            Logger.cards.warning("Block confirmation called without selected reason")
            return
        }

        dismissBlockAlert()
        isBlocking = true
        error = nil
        defer { isBlocking = false }

        Logger.cards.debug("Attempting to block card: \(self.cardId) with reason: \(reason.rawValue)")

        do {
            let _ = try await cardService.blockCard(id: cardId, reason: reason)
            isSuccess = true
            Logger.cards.info("Card blocked successfully: \(self.cardId)")

            // Auto-navigate back after brief delay to show success state
            try? await Task.sleep(nanoseconds: 1_500_000_000) // 1.5 seconds
            coordinator?.pop()
        } catch {
            self.error = error
            Logger.cards.error("Card block failed for \(self.cardId): \(error.localizedDescription)")
        }
    }

    // MARK: - Unblock Methods

    /// Shows the unblock confirmation alert
    func showUnblockAlert() {
        showUnblockConfirmation = true
    }

    /// Dismisses the unblock confirmation alert
    func dismissUnblockAlert() {
        showUnblockConfirmation = false
    }

    /// Confirms and executes the unblock operation
    @MainActor
    func confirmUnblock() async {
        guard canUnblock else {
            error = CardError.cannotUnblock
            Logger.cards.warning("Unblock attempted for card that cannot be unblocked: \(self.cardId)")
            return
        }

        dismissUnblockAlert()
        isUnblocking = true
        error = nil
        defer { isUnblocking = false }

        Logger.cards.debug("Attempting to unblock card: \(self.cardId)")

        do {
            let _ = try await cardService.unblockCard(id: cardId)
            isSuccess = true
            Logger.cards.info("Card unblocked successfully: \(self.cardId)")

            // Auto-navigate back after brief delay to show success state
            try? await Task.sleep(nanoseconds: 1_500_000_000) // 1.5 seconds
            coordinator?.pop()
        } catch {
            self.error = error
            Logger.cards.error("Card unblock failed for \(self.cardId): \(error.localizedDescription)")
        }
    }

    // MARK: - Navigation Methods

    /// Cancels the operation and navigates back
    func cancel() {
        Logger.cards.debug("Block/unblock operation cancelled for card: \(self.cardId)")
        coordinator?.pop()
    }

    /// Navigates to support (for cards that cannot be unblocked)
    func contactSupport() {
        Logger.cards.debug("Contact support requested for card: \(self.cardId)")
        coordinator?.navigateToSupport()
    }

    // MARK: - Helper Methods

    /// Clears any existing error
    func clearError() {
        error = nil
    }

    /// Selects a block reason and clears any error
    func selectReason(_ reason: BlockReason) {
        selectedReason = reason
        clearError()
    }

    /// Updates additional notes
    func updateNotes(_ notes: String) {
        additionalNotes = notes
    }
}
