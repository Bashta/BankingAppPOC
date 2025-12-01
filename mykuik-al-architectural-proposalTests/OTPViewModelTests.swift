// OTPViewModelTests.swift
// BankingApp Tests
//
// Unit tests for OTPViewModel covering verification flows,
// timer management, error handling, and resend functionality.

import Foundation
import Testing
import Combine
@testable import mykuik_al_architectural_proposal

// MARK: - Mock AuthService for OTP Testing

final class MockAuthServiceForOTP: AuthServiceProtocol {
    @Published private(set) var isAuthenticated: Bool = false

    var isAuthenticatedPublisher: AnyPublisher<Bool, Never> {
        $isAuthenticated.eraseToAnyPublisher()
    }

    // OTP verification mocking
    var verifyOTPCalled = false
    var lastVerifiedReference: OTPReference?
    var lastVerifiedCode: String?
    var mockVerifyOTPResult: AuthToken = AuthToken(
        accessToken: "test-token",
        refreshToken: "test-refresh",
        expiresAt: Date().addingTimeInterval(3600)
    )
    var mockVerifyOTPError: Error?
    var shouldSetAuthenticatedOnVerify = true

    func login(username: String, password: String) async throws -> LoginResult {
        fatalError("Not used in OTP tests")
    }

    func loginWithBiometric() async throws -> LoginResult {
        fatalError("Not used in OTP tests")
    }

    func verifyOTP(reference: OTPReference, code: String) async throws -> AuthToken {
        verifyOTPCalled = true
        lastVerifiedReference = reference
        lastVerifiedCode = code

        if let error = mockVerifyOTPError {
            throw error
        }

        if shouldSetAuthenticatedOnVerify && reference.purpose == .login {
            isAuthenticated = true
        }

        return mockVerifyOTPResult
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
        fatalError("Not used in OTP tests")
    }

    func updateUserProfile(_ user: User) async throws -> User {
        fatalError("Not used in OTP tests")
    }
}

// MARK: - OTPViewModel Tests

@Suite("OTPViewModel")
struct OTPViewModelTests {

    // MARK: - Initialization Tests

    @Test("ViewModel initializes with correct OTP reference")
    func initializationWithReference() {
        let otpReference = OTPReference(
            id: "OTP-123",
            expiresAt: Date().addingTimeInterval(300),
            purpose: .login
        )

        let viewModel = createViewModel(otpReference: otpReference)

        #expect(viewModel.otpReference.id == "OTP-123")
        #expect(viewModel.otpReference.purpose == .login)
        #expect(viewModel.otpCode == "")
        #expect(!viewModel.isLoading)
        #expect(viewModel.error == nil)
        #expect(!viewModel.isExpired)
        #expect(!viewModel.isSuccess)
    }

    @Test("ViewModel initializes timer with positive time remaining")
    func initializationStartsTimer() {
        let otpReference = OTPReference(
            id: "OTP-123",
            expiresAt: Date().addingTimeInterval(300), // 5 minutes
            purpose: .login
        )

        let viewModel = createViewModel(otpReference: otpReference)

        // Time remaining should be close to 300 seconds (allowing for test execution time)
        #expect(viewModel.timeRemaining > 290)
        #expect(viewModel.timeRemaining <= 300)
        #expect(!viewModel.isExpired)
    }

    @Test("ViewModel detects already expired OTP reference")
    func initializationDetectsExpired() {
        let otpReference = OTPReference(
            id: "OTP-EXPIRED",
            expiresAt: Date().addingTimeInterval(-60), // Expired 1 minute ago
            purpose: .login
        )

        let viewModel = createViewModel(otpReference: otpReference)

        #expect(viewModel.timeRemaining == 0)
        #expect(viewModel.isExpired)
    }

    // MARK: - Code Validation Tests

    @Test("isValidCode returns false for empty code")
    func emptyCodeInvalid() {
        let viewModel = createViewModel()
        viewModel.otpCode = ""

        #expect(!viewModel.isValidCode)
    }

    @Test("isValidCode returns false for partial code")
    func partialCodeInvalid() {
        let viewModel = createViewModel()
        viewModel.otpCode = "123"

        #expect(!viewModel.isValidCode)
    }

    @Test("isValidCode returns true for 6-digit code")
    func sixDigitCodeValid() {
        let viewModel = createViewModel()
        viewModel.otpCode = "123456"

        #expect(viewModel.isValidCode)
    }

    @Test("isValidCode returns false for non-numeric code")
    func nonNumericCodeInvalid() {
        let viewModel = createViewModel()
        viewModel.otpCode = "12345A"

        #expect(!viewModel.isValidCode)
    }

    @Test("canVerify combines validation with state")
    func canVerifyValidation() {
        let viewModel = createViewModel()

        // Empty code
        viewModel.otpCode = ""
        #expect(!viewModel.canVerify)

        // Valid code
        viewModel.otpCode = "123456"
        #expect(viewModel.canVerify)
    }

    @Test("canVerify returns false when expired")
    func canVerifyExpired() {
        let otpReference = OTPReference(
            id: "OTP-EXPIRED",
            expiresAt: Date().addingTimeInterval(-60),
            purpose: .login
        )

        let viewModel = createViewModel(otpReference: otpReference)
        viewModel.otpCode = "123456" // Valid code

        #expect(!viewModel.canVerify) // Should be false due to expiration
    }

    // MARK: - Timer Display Tests

    @Test("formattedTimeRemaining formats correctly")
    func timeFormattingCorrect() {
        let viewModel = createViewModel()

        // Test various times (cannot directly test due to timer)
        // Just verify format is MM:SS
        let formatted = viewModel.formattedTimeRemaining
        #expect(formatted.contains(":"))
        #expect(formatted.count == 5) // "MM:SS"
    }

    @Test("isTimerWarning triggers under 60 seconds")
    func timerWarningThreshold() {
        // Create OTP expiring in 30 seconds
        let otpReference = OTPReference(
            id: "OTP-WARNING",
            expiresAt: Date().addingTimeInterval(30),
            purpose: .login
        )

        let viewModel = createViewModel(otpReference: otpReference)

        #expect(viewModel.isTimerWarning) // Should be in warning state
    }

    @Test("isTimerWarning false when over 60 seconds")
    func noTimerWarningAboveThreshold() {
        let otpReference = OTPReference(
            id: "OTP-OK",
            expiresAt: Date().addingTimeInterval(120),
            purpose: .login
        )

        let viewModel = createViewModel(otpReference: otpReference)

        #expect(!viewModel.isTimerWarning)
    }

    // MARK: - Verification Success Tests

    @Test("verifyOTP succeeds with correct code")
    @MainActor
    func verifyOTPSuccess() async {
        let authService = MockAuthServiceForOTP()
        let viewModel = createViewModel(authService: authService)

        viewModel.otpCode = "123456"

        await viewModel.verifyOTP()

        #expect(authService.verifyOTPCalled)
        #expect(authService.lastVerifiedCode == "123456")
        #expect(viewModel.isSuccess)
        #expect(viewModel.error == nil)
        #expect(authService.isAuthenticated) // For login purpose
    }

    @Test("verifyOTP passes correct OTP reference")
    @MainActor
    func verifyOTPPassesReference() async {
        let authService = MockAuthServiceForOTP()
        let otpReference = OTPReference(
            id: "OTP-SPECIFIC",
            expiresAt: Date().addingTimeInterval(300),
            purpose: .transfer
        )

        let viewModel = createViewModel(authService: authService, otpReference: otpReference)
        viewModel.otpCode = "654321"

        await viewModel.verifyOTP()

        #expect(authService.lastVerifiedReference?.id == "OTP-SPECIFIC")
        #expect(authService.lastVerifiedReference?.purpose == .transfer)
    }

    // MARK: - Verification Error Tests

    @Test("verifyOTP handles invalid code error")
    @MainActor
    func verifyOTPInvalidCode() async {
        let authService = MockAuthServiceForOTP()
        authService.mockVerifyOTPError = AuthError.invalidOTP

        let viewModel = createViewModel(authService: authService)
        viewModel.otpCode = "999999"

        await viewModel.verifyOTP()

        #expect(!viewModel.isSuccess)
        #expect(viewModel.error != nil)
        #expect(viewModel.otpCode == "") // Should clear code for retry
    }

    @Test("verifyOTP handles expired OTP error")
    @MainActor
    func verifyOTPExpiredError() async {
        let authService = MockAuthServiceForOTP()
        authService.mockVerifyOTPError = AuthError.otpExpired

        let viewModel = createViewModel(authService: authService)
        viewModel.otpCode = "123456"

        await viewModel.verifyOTP()

        #expect(!viewModel.isSuccess)
        #expect(viewModel.isExpired)
        #expect(viewModel.error != nil)
    }

    @Test("verifyOTP guards against invalid code")
    @MainActor
    func verifyOTPGuardsInvalidCode() async {
        let authService = MockAuthServiceForOTP()
        let viewModel = createViewModel(authService: authService)

        viewModel.otpCode = "123" // Invalid - too short

        await viewModel.verifyOTP()

        #expect(!authService.verifyOTPCalled) // Should not call service
        #expect(viewModel.error != nil) // Should set validation error
    }

    @Test("verifyOTP guards against expired state")
    @MainActor
    func verifyOTPGuardsExpired() async {
        let authService = MockAuthServiceForOTP()
        let otpReference = OTPReference(
            id: "OTP-EXPIRED",
            expiresAt: Date().addingTimeInterval(-60),
            purpose: .login
        )

        let viewModel = createViewModel(authService: authService, otpReference: otpReference)
        viewModel.otpCode = "123456"

        await viewModel.verifyOTP()

        #expect(!authService.verifyOTPCalled) // Should not call service
        #expect(viewModel.error != nil)
    }

    // MARK: - Resend OTP Tests

    @Test("resendOTP resets timer and state")
    @MainActor
    func resendOTPResetsState() async {
        let otpReference = OTPReference(
            id: "OTP-EXPIRED",
            expiresAt: Date().addingTimeInterval(-60), // Expired
            purpose: .login
        )

        let viewModel = createViewModel(otpReference: otpReference)

        #expect(viewModel.isExpired) // Verify initial expired state

        await viewModel.resendOTP()

        #expect(!viewModel.isExpired) // Should be reset
        #expect(viewModel.timeRemaining > 0) // Timer should be restarted
        #expect(viewModel.otpCode == "") // Code should be cleared
        #expect(viewModel.error == nil) // Error should be cleared
    }

    // MARK: - Cancel Tests

    @Test("cancel triggers dismiss callback")
    func cancelTriggersDismiss() {
        let viewModel = createViewModel()

        var dismissCalled = false
        viewModel.onDismiss = {
            dismissCalled = true
        }

        viewModel.cancel()

        #expect(dismissCalled)
    }

    // MARK: - Purpose Display Tests

    @Test("purposeMessage returns correct message for login")
    func purposeMessageLogin() {
        let otpReference = OTPReference(
            id: "OTP-1",
            expiresAt: Date().addingTimeInterval(300),
            purpose: .login
        )

        let viewModel = createViewModel(otpReference: otpReference)

        #expect(viewModel.purposeMessage.contains("login"))
    }

    @Test("purposeMessage returns correct message for transfer")
    func purposeMessageTransfer() {
        let otpReference = OTPReference(
            id: "OTP-1",
            expiresAt: Date().addingTimeInterval(300),
            purpose: .transfer
        )

        let viewModel = createViewModel(otpReference: otpReference)

        #expect(viewModel.purposeMessage.contains("transfer"))
    }

    @Test("purposeIcon returns correct icon for different purposes")
    func purposeIconVariety() {
        let loginRef = OTPReference(id: "1", expiresAt: Date().addingTimeInterval(300), purpose: .login)
        let transferRef = OTPReference(id: "2", expiresAt: Date().addingTimeInterval(300), purpose: .transfer)

        let loginVM = createViewModel(otpReference: loginRef)
        let transferVM = createViewModel(otpReference: transferRef)

        #expect(loginVM.purposeIcon.contains("shield") || loginVM.purposeIcon.contains("lock"))
        #expect(transferVM.purposeIcon.contains("arrow"))
    }

    // MARK: - Loading State Tests

    @Test("isLoading is managed during verification")
    @MainActor
    func loadingStateManagement() async {
        let authService = MockAuthServiceForOTP()
        let viewModel = createViewModel(authService: authService)

        viewModel.otpCode = "123456"

        // After completion
        await viewModel.verifyOTP()

        #expect(!viewModel.isLoading) // Should be false after completion
    }

    // MARK: - Helper Methods

    private func createViewModel(
        authService: AuthServiceProtocol? = nil,
        otpReference: OTPReference? = nil
    ) -> OTPViewModel {
        let container = DependencyContainer()
        let appCoordinator = AppCoordinator(dependencyContainer: container)
        let coordinator = AuthCoordinator(parent: appCoordinator, dependencyContainer: container)

        let reference = otpReference ?? OTPReference(
            id: "OTP-DEFAULT",
            expiresAt: Date().addingTimeInterval(300),
            purpose: .login
        )

        return OTPViewModel(
            otpReference: reference,
            authService: authService ?? MockAuthServiceForOTP(),
            coordinator: coordinator
        )
    }
}

// MARK: - OTPPurpose Extension Tests

@Suite("OTPPurpose")
struct OTPPurposeTests {

    @Test("All purposes have display messages")
    func allPurposesHaveMessages() {
        #expect(!OTPPurpose.login.displayMessage.isEmpty)
        #expect(!OTPPurpose.transfer.displayMessage.isEmpty)
        #expect(!OTPPurpose.cardPINChange.displayMessage.isEmpty)
        #expect(!OTPPurpose.passwordReset.displayMessage.isEmpty)
    }

    @Test("All purposes have icons")
    func allPurposesHaveIcons() {
        #expect(!OTPPurpose.login.icon.isEmpty)
        #expect(!OTPPurpose.transfer.icon.isEmpty)
        #expect(!OTPPurpose.cardPINChange.icon.isEmpty)
        #expect(!OTPPurpose.passwordReset.icon.isEmpty)
    }
}

// MARK: - OTPValidationError Tests

@Suite("OTPValidationError")
struct OTPValidationErrorTests {

    @Test("Validation errors have descriptions")
    func validationErrorDescriptions() {
        #expect(OTPValidationError.invalidLength.errorDescription != nil)
        #expect(OTPValidationError.nonNumericCharacters.errorDescription != nil)
    }
}
