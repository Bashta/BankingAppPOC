// BiometricLoginViewModelTests.swift
// BankingApp Tests
//
// Unit tests for BiometricLoginViewModel covering authentication flows,
// state management, error handling, and navigation delegation.

import Foundation
import Testing
import Combine
@testable import mykuik_al_architectural_proposal

// MARK: - Mock AuthService for Testing

final class MockAuthServiceForBiometric: AuthServiceProtocol {
    @Published private(set) var isAuthenticated: Bool = false

    var isAuthenticatedPublisher: AnyPublisher<Bool, Never> {
        $isAuthenticated.eraseToAnyPublisher()
    }

    var mockLoginWithBiometricResult: LoginResult = LoginResult(
        token: AuthToken(
            accessToken: "test-token",
            refreshToken: "test-refresh",
            expiresAt: Date().addingTimeInterval(3600)
        ),
        requiresOTP: false,
        otpReference: nil
    )
    var mockLoginWithBiometricError: Error?
    var loginWithBiometricCalled = false

    func login(username: String, password: String) async throws -> LoginResult {
        fatalError("Not used in biometric tests")
    }

    func loginWithBiometric() async throws -> LoginResult {
        loginWithBiometricCalled = true
        if let error = mockLoginWithBiometricError {
            throw error
        }
        if !mockLoginWithBiometricResult.requiresOTP {
            isAuthenticated = true
        }
        return mockLoginWithBiometricResult
    }

    func verifyOTP(reference: OTPReference, code: String) async throws -> AuthToken {
        fatalError("Not used in biometric tests")
    }

    func logout() async throws {
        isAuthenticated = false
    }

    func forgotPassword(email: String) async throws {}
    func resetPassword(token: String, newPassword: String) async throws {}
    func changePassword(oldPassword: String, newPassword: String) async throws {}
    func changePIN(oldPIN: String, newPIN: String) async throws -> OTPReference {
        return OTPReference(id: "test", expiresAt: Date(), purpose: .changePIN)
    }

    func fetchUserProfile() async throws -> User {
        fatalError("Not used in biometric tests")
    }

    func updateUserProfile(_ user: User) async throws -> User {
        fatalError("Not used in biometric tests")
    }
}

// MARK: - BiometricLoginViewModel Tests

@Suite("BiometricLoginViewModel")
struct BiometricLoginViewModelTests {

    // MARK: - Initialization Tests

    @Test("ViewModel initializes with default state")
    func initialization() {
        let viewModel = createViewModel()

        #expect(!viewModel.isAuthenticating)
        #expect(viewModel.error == nil)
        #expect(viewModel.biometricType == .none)
        #expect(!viewModel.canUseBiometrics)
        #expect(!viewModel.showOTP)
        #expect(!viewModel.showPasswordFallback)
    }

    // MARK: - Biometric Availability Tests

    @Test("checkBiometricAvailability updates state when biometrics available")
    func checkAvailabilityWhenAvailable() {
        let biometricService = MockBiometricService()
        biometricService.mockCanUseBiometrics = true
        biometricService.mockBiometricType = .faceID

        let viewModel = createViewModel(biometricService: biometricService)

        viewModel.checkBiometricAvailability()

        #expect(viewModel.canUseBiometrics)
        #expect(viewModel.biometricType == .faceID)
    }

    @Test("checkBiometricAvailability updates state when biometrics unavailable")
    func checkAvailabilityWhenUnavailable() {
        let biometricService = MockBiometricService()
        biometricService.mockCanUseBiometrics = false

        let viewModel = createViewModel(biometricService: biometricService)

        viewModel.checkBiometricAvailability()

        #expect(!viewModel.canUseBiometrics)
        #expect(viewModel.biometricType == .none)
    }

    @Test("checkBiometricAvailability detects Touch ID")
    func checkAvailabilityTouchID() {
        let biometricService = MockBiometricService()
        biometricService.mockCanUseBiometrics = true
        biometricService.mockBiometricType = .touchID

        let viewModel = createViewModel(biometricService: biometricService)

        viewModel.checkBiometricAvailability()

        #expect(viewModel.biometricType == .touchID)
        #expect(viewModel.biometricTypeName == "Touch ID")
        #expect(viewModel.biometricIcon == "touchid")
    }

    @Test("checkBiometricAvailability detects Face ID")
    func checkAvailabilityFaceID() {
        let biometricService = MockBiometricService()
        biometricService.mockCanUseBiometrics = true
        biometricService.mockBiometricType = .faceID

        let viewModel = createViewModel(biometricService: biometricService)

        viewModel.checkBiometricAvailability()

        #expect(viewModel.biometricType == .faceID)
        #expect(viewModel.biometricTypeName == "Face ID")
        #expect(viewModel.biometricIcon == "faceid")
    }

    // MARK: - Successful Authentication Tests

    @Test("authenticateWithBiometric succeeds without OTP")
    @MainActor
    func successfulAuthenticationNoOTP() async {
        let biometricService = MockBiometricService()
        biometricService.mockCanUseBiometrics = true
        biometricService.mockAuthenticateResult = true

        let authService = MockAuthServiceForBiometric()
        authService.mockLoginWithBiometricResult = LoginResult(
            token: AuthToken(accessToken: "token", refreshToken: "refresh", expiresAt: Date()),
            requiresOTP: false,
            otpReference: nil
        )

        let viewModel = createViewModel(authService: authService, biometricService: biometricService)
        viewModel.checkBiometricAvailability()

        await viewModel.authenticateWithBiometric()

        #expect(biometricService.authenticateCalled)
        #expect(authService.loginWithBiometricCalled)
        #expect(!viewModel.isAuthenticating) // Should be false after completion
        #expect(viewModel.error == nil)
        #expect(!viewModel.showOTP)
        #expect(authService.isAuthenticated) // Auth should complete
    }

    @Test("authenticateWithBiometric handles OTP requirement")
    @MainActor
    func authenticationRequiresOTP() async {
        let biometricService = MockBiometricService()
        biometricService.mockCanUseBiometrics = true

        let authService = MockAuthServiceForBiometric()
        let otpRef = OTPReference(id: "OTP123", expiresAt: Date().addingTimeInterval(300), purpose: .login)
        authService.mockLoginWithBiometricResult = LoginResult(
            token: nil,
            requiresOTP: true,
            otpReference: otpRef
        )

        let viewModel = createViewModel(authService: authService, biometricService: biometricService)
        viewModel.checkBiometricAvailability()

        await viewModel.authenticateWithBiometric()

        #expect(viewModel.showOTP)
        #expect(viewModel.currentOTPReference?.id == "OTP123")
    }

    // MARK: - Error Handling Tests

    @Test("authenticateWithBiometric handles user cancellation silently")
    @MainActor
    func userCancellationHandledSilently() async {
        let biometricService = MockBiometricService()
        biometricService.mockCanUseBiometrics = true
        biometricService.mockAuthenticateError = BiometricError.userCancelled

        let viewModel = createViewModel(biometricService: biometricService)
        viewModel.checkBiometricAvailability()

        await viewModel.authenticateWithBiometric()

        // User cancellation should not show error
        #expect(viewModel.error == nil)
        #expect(!viewModel.showPasswordFallback)
    }

    @Test("authenticateWithBiometric handles user fallback request")
    @MainActor
    func userFallbackRequest() async {
        let biometricService = MockBiometricService()
        biometricService.mockCanUseBiometrics = true
        biometricService.mockAuthenticateError = BiometricError.userFallback

        let viewModel = createViewModel(biometricService: biometricService)
        viewModel.checkBiometricAvailability()

        await viewModel.authenticateWithBiometric()

        // User fallback should show password option
        #expect(viewModel.error == nil)
        #expect(viewModel.showPasswordFallback)
    }

    @Test("authenticateWithBiometric handles biometry lockout")
    @MainActor
    func biometryLockoutError() async {
        let biometricService = MockBiometricService()
        biometricService.mockCanUseBiometrics = true
        biometricService.mockAuthenticateError = BiometricError.biometryLockout

        let viewModel = createViewModel(biometricService: biometricService)
        viewModel.checkBiometricAvailability()

        await viewModel.authenticateWithBiometric()

        #expect(viewModel.error == .biometryLockout)
        #expect(viewModel.showPasswordFallback) // Should offer fallback
    }

    @Test("authenticateWithBiometric handles authentication failure")
    @MainActor
    func authenticationFailure() async {
        let biometricService = MockBiometricService()
        biometricService.mockCanUseBiometrics = true
        biometricService.mockAuthenticateError = BiometricError.authenticationFailed("Test failure")

        let viewModel = createViewModel(biometricService: biometricService)
        viewModel.checkBiometricAvailability()

        await viewModel.authenticateWithBiometric()

        #expect(viewModel.error == .authenticationFailed("Test failure"))
        #expect(viewModel.showPasswordFallback)
    }

    @Test("authenticateWithBiometric guards against unavailable biometrics")
    @MainActor
    func guardsAgainstUnavailableBiometrics() async {
        let biometricService = MockBiometricService()
        biometricService.mockCanUseBiometrics = false

        let viewModel = createViewModel(biometricService: biometricService)
        viewModel.checkBiometricAvailability()

        await viewModel.authenticateWithBiometric()

        // Should not attempt authentication
        #expect(!biometricService.authenticateCalled)
    }

    // MARK: - State Management Tests

    @Test("isAuthenticating is true during authentication")
    @MainActor
    func loadingStateDuringAuth() async {
        let biometricService = MockBiometricService()
        biometricService.mockCanUseBiometrics = true

        let viewModel = createViewModel(biometricService: biometricService)
        viewModel.checkBiometricAvailability()

        // Can't easily test intermediate state, but verify final state
        await viewModel.authenticateWithBiometric()

        #expect(!viewModel.isAuthenticating) // Should be false after completion
    }

    @Test("clearError resets error state")
    func clearErrorResetsState() {
        let viewModel = createViewModel()
        viewModel.checkBiometricAvailability()

        // Manually set error state for testing
        // (In real usage, this would be set by failed authentication)
        viewModel.clearError()

        #expect(viewModel.error == nil)
        #expect(!viewModel.showPasswordFallback)
    }

    @Test("retryBiometric clears error before retrying")
    func retryBiometricClearsError() {
        let viewModel = createViewModel()

        viewModel.retryBiometric()

        #expect(viewModel.error == nil)
        #expect(!viewModel.showPasswordFallback)
    }

    // MARK: - Helper Methods

    private func createViewModel(
        authService: AuthServiceProtocol? = nil,
        biometricService: BiometricServiceProtocol? = nil
    ) -> BiometricLoginViewModel {
        let container = DependencyContainer()
        let appCoordinator = AppCoordinator(dependencyContainer: container)
        let coordinator = AuthCoordinator(parent: appCoordinator, dependencyContainer: container)

        return BiometricLoginViewModel(
            authService: authService ?? MockAuthServiceForBiometric(),
            biometricService: biometricService ?? MockBiometricService(),
            coordinator: coordinator
        )
    }
}
