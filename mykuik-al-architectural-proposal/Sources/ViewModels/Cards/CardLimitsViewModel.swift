//
//  CardLimitsViewModel.swift
//  BankingApp
//
//  ViewModel for Card Spending Limits View - manages loading, validation,
//  editing, and saving of card spending limits.
//  Story 5.5: Implement Card Spending Limits Management
//

import Foundation
import Combine
import OSLog

// MARK: - LimitField Enum

enum LimitField: String, CaseIterable {
    case dailyPurchase
    case dailyWithdrawal
    case onlineTransaction
    case contactless

    var displayName: String {
        switch self {
        case .dailyPurchase:
            return "Daily Purchase"
        case .dailyWithdrawal:
            return "Daily Withdrawal"
        case .onlineTransaction:
            return "Online Transaction"
        case .contactless:
            return "Contactless"
        }
    }

    var maxValue: Decimal {
        switch self {
        case .dailyPurchase:
            return CardLimits.maxDailyPurchase
        case .dailyWithdrawal:
            return CardLimits.maxDailyWithdrawal
        case .onlineTransaction:
            return CardLimits.maxOnlineTransaction
        case .contactless:
            return CardLimits.maxContactless
        }
    }

    var iconName: String {
        switch self {
        case .dailyPurchase:
            return "cart.fill"
        case .dailyWithdrawal:
            return "banknote.fill"
        case .onlineTransaction:
            return "globe"
        case .contactless:
            return "wave.3.right"
        }
    }
}

// MARK: - CardLimitsViewModel

final class CardLimitsViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published var limits: CardLimits?
    @Published var dailyPurchase: Decimal = 0
    @Published var dailyWithdrawal: Decimal = 0
    @Published var onlineTransaction: Decimal = 0
    @Published var contactless: Decimal = 0
    @Published var isLoading = false
    @Published var isSaving = false
    @Published var isSuccess = false
    @Published var error: Error?
    @Published var validationErrors: [String: String] = [:]

    // MARK: - Properties

    let cardId: String

    // MARK: - Dependencies

    private let cardService: CardServiceProtocol
    weak var coordinator: CardsCoordinator?

    // MARK: - Computed Properties - Validation

    var isDailyPurchaseValid: Bool {
        dailyPurchase > 0 && dailyPurchase <= CardLimits.maxDailyPurchase
    }

    var isDailyWithdrawalValid: Bool {
        dailyWithdrawal > 0 && dailyWithdrawal <= CardLimits.maxDailyWithdrawal
    }

    var isOnlineTransactionValid: Bool {
        onlineTransaction > 0 && onlineTransaction <= CardLimits.maxOnlineTransaction
    }

    var isContactlessValid: Bool {
        contactless > 0 && contactless <= CardLimits.maxContactless
    }

    var isAllValid: Bool {
        isDailyPurchaseValid && isDailyWithdrawalValid && isOnlineTransactionValid && isContactlessValid
    }

    var hasChanges: Bool {
        guard let limits = limits else { return false }
        return dailyPurchase != limits.dailyPurchase ||
               dailyWithdrawal != limits.dailyWithdrawal ||
               onlineTransaction != limits.onlineTransaction ||
               contactless != limits.contactless
    }

    // MARK: - Initialization

    init(cardId: String, cardService: CardServiceProtocol, coordinator: CardsCoordinator) {
        self.cardId = cardId
        self.cardService = cardService
        self.coordinator = coordinator

        Logger.cards.debug("CardLimitsViewModel initialized for card: \(cardId)")
    }

    // MARK: - Data Loading

    @MainActor
    func loadData() async {
        // Reset success state when reloading (handles cached ViewModel scenario)
        isSuccess = false
        isLoading = true
        error = nil
        validationErrors.removeAll()
        defer { isLoading = false }

        Logger.cards.debug("Loading limits for card: \(self.cardId)")

        do {
            let card = try await cardService.fetchCard(id: cardId)
            limits = card.limits
            dailyPurchase = card.limits.dailyPurchase
            dailyWithdrawal = card.limits.dailyWithdrawal
            onlineTransaction = card.limits.onlineTransaction
            contactless = card.limits.contactless
            Logger.cards.info("Limits loaded successfully for card: \(self.cardId)")
        } catch {
            self.error = error
            Logger.cards.error("Failed to load limits for card \(self.cardId): \(error.localizedDescription)")
        }
    }

    // MARK: - Validation

    func validateField(_ field: LimitField) {
        let value: Decimal
        let maxValue = field.maxValue

        switch field {
        case .dailyPurchase:
            value = dailyPurchase
        case .dailyWithdrawal:
            value = dailyWithdrawal
        case .onlineTransaction:
            value = onlineTransaction
        case .contactless:
            value = contactless
        }

        if value <= 0 {
            validationErrors[field.rawValue] = "Must be greater than $0"
        } else if value > maxValue {
            validationErrors[field.rawValue] = "Cannot exceed $\(maxValue)"
        } else {
            validationErrors.removeValue(forKey: field.rawValue)
        }
    }

    func clearFieldError(_ field: LimitField) {
        validationErrors.removeValue(forKey: field.rawValue)
        error = nil
    }

    func validationError(for field: LimitField) -> String? {
        validationErrors[field.rawValue]
    }

    // MARK: - Save Functionality

    @MainActor
    func saveLimits() async {
        // Validate all fields first
        for field in LimitField.allCases {
            validateField(field)
        }

        guard isAllValid else {
            Logger.cards.warning("Save attempted with invalid limits for card: \(self.cardId)")
            return
        }

        guard hasChanges else {
            Logger.cards.debug("No changes to save for card: \(self.cardId)")
            return
        }

        isSaving = true
        error = nil
        defer { isSaving = false }

        Logger.cards.debug("Saving limits for card: \(self.cardId)")

        let newLimits = CardLimits(
            dailyPurchase: dailyPurchase,
            dailyWithdrawal: dailyWithdrawal,
            onlineTransaction: onlineTransaction,
            contactless: contactless
        )

        do {
            let updatedCard = try await cardService.updateLimits(id: cardId, limits: newLimits)
            limits = updatedCard.limits
            isSuccess = true
            Logger.cards.info("Limits saved successfully for card: \(self.cardId)")

            // Auto-navigate back after brief delay to show success state
            try? await Task.sleep(nanoseconds: 1_500_000_000) // 1.5 seconds
            coordinator?.pop()
        } catch {
            self.error = error
            Logger.cards.error("Failed to save limits for card \(self.cardId): \(error.localizedDescription)")
        }
    }

    // MARK: - Navigation

    func cancel() {
        Logger.cards.debug("Limits edit cancelled for card: \(self.cardId)")
        coordinator?.pop()
    }

    // MARK: - Helper Methods

    func clearError() {
        error = nil
    }

    /// Updates a field value and clears its validation error
    func updateValue(for field: LimitField, value: Decimal) {
        switch field {
        case .dailyPurchase:
            dailyPurchase = value
        case .dailyWithdrawal:
            dailyWithdrawal = value
        case .onlineTransaction:
            onlineTransaction = value
        case .contactless:
            contactless = value
        }
        clearFieldError(field)
    }

    /// Gets the current value for a field
    func value(for field: LimitField) -> Decimal {
        switch field {
        case .dailyPurchase:
            return dailyPurchase
        case .dailyWithdrawal:
            return dailyWithdrawal
        case .onlineTransaction:
            return onlineTransaction
        case .contactless:
            return contactless
        }
    }

    /// Gets the original value for a field (from loaded limits)
    func originalValue(for field: LimitField) -> Decimal? {
        guard let limits = limits else { return nil }
        switch field {
        case .dailyPurchase:
            return limits.dailyPurchase
        case .dailyWithdrawal:
            return limits.dailyWithdrawal
        case .onlineTransaction:
            return limits.onlineTransaction
        case .contactless:
            return limits.contactless
        }
    }

    /// Returns whether a specific field has changed from original
    func hasChanged(field: LimitField) -> Bool {
        guard let original = originalValue(for: field) else { return false }
        return value(for: field) != original
    }
}
