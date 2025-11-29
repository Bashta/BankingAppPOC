// BiometricServiceTests.swift
// BankingApp Tests
//
// Unit tests for BiometricService with LocalAuthentication integration.
// Tests biometric availability detection, type detection, and error handling.

import Foundation
import Testing
@testable import mykuik_al_architectural_proposal

// MARK: - BiometricError Tests

@Suite("BiometricError")
struct BiometricErrorTests {

    @Test("User-friendly messages are provided for all error cases")
    func userFriendlyMessages() {
        // Test that all error cases have appropriate messages
        #expect(BiometricError.biometryNotAvailable.userFriendlyMessage.contains("not available"))
        #expect(BiometricError.biometryNotEnrolled.userFriendlyMessage.contains("enrolled"))
        #expect(BiometricError.biometryLockout.userFriendlyMessage.contains("locked"))
        #expect(BiometricError.passcodeNotSet.userFriendlyMessage.contains("passcode"))
        #expect(BiometricError.systemCancelled.userFriendlyMessage.contains("system"))
        #expect(BiometricError.authenticationFailed("Test error").userFriendlyMessage == "Test error")
    }

    @Test("User cancelled and user fallback return empty messages")
    func silentErrors() {
        // User cancelled - no message needed
        #expect(BiometricError.userCancelled.userFriendlyMessage.isEmpty)
        // User chose fallback - no message needed
        #expect(BiometricError.userFallback.userFriendlyMessage.isEmpty)
    }

    @Test("shouldShowAlert returns false for user-initiated actions")
    func shouldShowAlertProperty() {
        // User cancelled - don't show alert
        #expect(!BiometricError.userCancelled.shouldShowAlert)
        // User chose fallback - don't show alert
        #expect(!BiometricError.userFallback.shouldShowAlert)
        // System errors should show alert
        #expect(BiometricError.biometryNotAvailable.shouldShowAlert)
        #expect(BiometricError.biometryLockout.shouldShowAlert)
        #expect(BiometricError.authenticationFailed("Test").shouldShowAlert)
    }

    @Test("shouldOfferPasswordFallback returns true for appropriate errors")
    func shouldOfferFallbackProperty() {
        // User explicitly requested fallback
        #expect(BiometricError.userFallback.shouldOfferPasswordFallback)
        // Authentication failed - offer fallback
        #expect(BiometricError.authenticationFailed("Test").shouldOfferPasswordFallback)
        // Lockout - offer fallback
        #expect(BiometricError.biometryLockout.shouldOfferPasswordFallback)
        // Not available - no fallback needed (should hide biometric option entirely)
        #expect(!BiometricError.biometryNotAvailable.shouldOfferPasswordFallback)
    }

    @Test("BiometricError conforms to LocalizedError")
    func localizedErrorConformance() {
        let error: Error = BiometricError.biometryNotAvailable
        #expect(error.localizedDescription.contains("not available"))
    }

    @Test("BiometricError is Equatable")
    func equatableConformance() {
        #expect(BiometricError.userCancelled == BiometricError.userCancelled)
        #expect(BiometricError.biometryLockout == BiometricError.biometryLockout)
        #expect(BiometricError.authenticationFailed("A") == BiometricError.authenticationFailed("A"))
        #expect(BiometricError.authenticationFailed("A") != BiometricError.authenticationFailed("B"))
    }
}

// MARK: - BiometricType Tests

@Suite("BiometricType")
struct BiometricTypeTests {

    @Test("BiometricType has expected cases")
    func biometricTypeCases() {
        // Verify all expected cases exist
        let faceID = BiometricType.faceID
        let touchID = BiometricType.touchID
        let none = BiometricType.none

        #expect(faceID != touchID)
        #expect(touchID != none)
        #expect(faceID != none)
    }
}

// MARK: - Mock BiometricService for Testing

/// Mock BiometricService for testing ViewModel behavior
final class MockBiometricService: BiometricServiceProtocol {
    var mockCanUseBiometrics: Bool = true
    var mockBiometricType: BiometricType = .faceID
    var mockAuthenticateResult: Bool = true
    var mockAuthenticateError: Error?
    var authenticateCalled = false
    var lastAuthenticateReason: String?

    func canUseBiometrics() -> Bool {
        mockCanUseBiometrics
    }

    func biometricType() -> BiometricType {
        mockBiometricType
    }

    func authenticate(reason: String) async throws -> Bool {
        authenticateCalled = true
        lastAuthenticateReason = reason
        if let error = mockAuthenticateError {
            throw error
        }
        return mockAuthenticateResult
    }
}

// MARK: - BiometricService Protocol Tests

@Suite("BiometricServiceProtocol")
struct BiometricServiceProtocolTests {

    @Test("MockBiometricService conforms to protocol")
    func mockServiceConformance() {
        let service: BiometricServiceProtocol = MockBiometricService()
        #expect(service.canUseBiometrics() == true)
        #expect(service.biometricType() == .faceID)
    }

    @Test("Mock service tracks authenticate calls")
    func mockServiceTracking() async throws {
        let service = MockBiometricService()

        _ = try await service.authenticate(reason: "Test reason")

        #expect(service.authenticateCalled)
        #expect(service.lastAuthenticateReason == "Test reason")
    }

    @Test("Mock service can simulate authentication failure")
    func mockServiceFailure() async {
        let service = MockBiometricService()
        service.mockAuthenticateError = BiometricError.userCancelled

        do {
            _ = try await service.authenticate(reason: "Test")
            Issue.record("Expected error to be thrown")
        } catch let error as BiometricError {
            #expect(error == .userCancelled)
        } catch {
            Issue.record("Unexpected error type: \(error)")
        }
    }
}
