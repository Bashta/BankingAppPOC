//
//  CardPINChangeViewModel.swift
//  BankingApp
//
//  ViewModel for Card PIN Change Flow - manages OTP request,
//  OTP verification, success/error states, and navigation.
//  Story 5.6: Implement PIN Change Flow with OTP
//

import Foundation
import Combine
import OSLog

final class CardPINChangeViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published var showOTP = false
    @Published var otpReference: OTPReference?
    @Published var isRequestingOTP = false
    @Published var isVerifying = false
    @Published var isSuccess = false
    @Published var error: Error?

    // MARK: - Properties

    let cardId: String

    // MARK: - Dependencies

    private let cardService: CardServiceProtocol
    weak var coordinator: CardsCoordinator?

    // MARK: - Computed Properties

    /// Returns true if any async operation is in progress
    var isLoading: Bool {
        isRequestingOTP || isVerifying
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

        Logger.cards.debug("CardPINChangeViewModel initialized for card: \(cardId)")
    }

    // MARK: - OTP Request

    /// Requests a PIN change which triggers OTP delivery
    @MainActor
    func requestPINChange() async {
        isRequestingOTP = true
        error = nil
        defer { isRequestingOTP = false }

        Logger.cards.debug("Requesting PIN change for card: \(self.cardId)")

        do {
            let reference = try await cardService.requestPINChange(cardId: cardId)
            otpReference = reference
            showOTP = true
            Logger.cards.info("PIN change OTP requested successfully for card: \(self.cardId)")
        } catch {
            self.error = error
            Logger.cards.error("PIN change request failed for \(self.cardId): \(error.localizedDescription)")
        }
    }

    // MARK: - OTP Verification

    /// Verifies the OTP code to confirm PIN change request
    @MainActor
    func verifyAndChangePIN(otpCode: String) async {
        isVerifying = true
        error = nil
        defer { isVerifying = false }

        Logger.cards.debug("Verifying PIN change OTP for card: \(self.cardId)")

        do {
            let success = try await cardService.verifyPINChange(cardId: cardId, otpCode: otpCode)

            if success {
                // Dismiss OTP modal first
                showOTP = false
                otpReference = nil

                // Show success state
                isSuccess = true
                Logger.cards.info("PIN change verified successfully for card: \(self.cardId)")

                // Auto-navigate back after delay to show success message
                try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
                coordinator?.pop()
            }
        } catch {
            // Keep OTP modal open for retry on error
            self.error = error
            Logger.cards.error("PIN change verification failed for \(self.cardId): \(error.localizedDescription)")
        }
    }

    // MARK: - Helper Methods

    /// Dismisses the OTP modal and clears reference
    func dismissOTP() {
        showOTP = false
        otpReference = nil
        Logger.cards.debug("OTP modal dismissed for PIN change")
    }

    /// Clears any existing error
    func clearError() {
        error = nil
    }

    /// Cancels the PIN change operation and navigates back
    func cancel() {
        Logger.cards.debug("PIN change cancelled for card: \(self.cardId)")
        coordinator?.pop()
    }

    /// Resets all state for a fresh flow (called when view appears)
    func resetState() {
        showOTP = false
        otpReference = nil
        isRequestingOTP = false
        isVerifying = false
        isSuccess = false
        error = nil
        Logger.cards.debug("PIN change state reset for card: \(self.cardId)")
    }
}
