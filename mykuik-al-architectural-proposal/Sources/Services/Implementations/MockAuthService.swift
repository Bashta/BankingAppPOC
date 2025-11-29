import Foundation
import Combine

final class MockAuthService: AuthServiceProtocol {
    @Published private(set) var isAuthenticated: Bool = false

    var isAuthenticatedPublisher: AnyPublisher<Bool, Never> {
        $isAuthenticated.eraseToAnyPublisher()
    }

    private var currentUser: User?
    private var storedPassword: String = "password"
    private var storedPIN: String = "1234"

    func login(username: String, password: String) async throws -> LoginResult {
        try await Task.sleep(nanoseconds: 500_000_000) // 500ms

        guard username == "user", password == storedPassword else {
            throw AuthError.invalidCredentials
        }

        isAuthenticated = true

        let token = AuthToken(
            accessToken: "mock-token-\(UUID().uuidString)",
            refreshToken: "mock-refresh-\(UUID().uuidString)",
            expiresAt: Date().addingTimeInterval(3600) // 1 hour
        )

        currentUser = User(
            id: "USER001",
            username: username,
            name: "John Doe",
            email: "user@example.com",
            phoneNumber: "+1234567890",
            address: nil
        )

        return LoginResult(
            token: token,
            requiresOTP: false,
            otpReference: nil
        )
    }

    func loginWithBiometric() async throws -> LoginResult {
        try await Task.sleep(nanoseconds: 500_000_000) // 500ms

        // Simulate biometric success
        isAuthenticated = true

        let token = AuthToken(
            accessToken: "mock-biometric-token-\(UUID().uuidString)",
            refreshToken: "mock-refresh-\(UUID().uuidString)",
            expiresAt: Date().addingTimeInterval(3600) // 1 hour
        )

        currentUser = User(
            id: "USER001",
            username: "user",
            name: "John Doe",
            email: "user@example.com",
            phoneNumber: "+1234567890",
            address: nil
        )

        return LoginResult(
            token: token,
            requiresOTP: false,
            otpReference: nil
        )
    }

    func verifyOTP(reference: OTPReference, code: String) async throws -> AuthToken {
        try await Task.sleep(nanoseconds: 500_000_000) // 500ms

        guard code == "123456" else {
            throw AuthError.invalidOTP
        }

        guard reference.expiresAt > Date() else {
            throw AuthError.otpExpired
        }

        isAuthenticated = true

        return AuthToken(
            accessToken: "mock-otp-token-\(UUID().uuidString)",
            refreshToken: "mock-refresh-\(UUID().uuidString)",
            expiresAt: Date().addingTimeInterval(3600) // 1 hour
        )
    }

    func logout() async throws {
        try await Task.sleep(nanoseconds: 300_000_000) // 300ms

        isAuthenticated = false
        currentUser = nil
    }

    func forgotPassword(email: String) async throws {
        try await Task.sleep(nanoseconds: 500_000_000) // 500ms

        // Simulate sending reset email
        guard email.contains("@") else {
            throw AuthError.invalidEmail
        }

        // Email sent (no actual email in mock)
    }

    func resetPassword(token: String, newPassword: String) async throws {
        try await Task.sleep(nanoseconds: 500_000_000) // 500ms

        guard !token.isEmpty else {
            throw AuthError.invalidToken
        }

        guard newPassword.count >= 8 else {
            throw AuthError.passwordTooWeak
        }

        storedPassword = newPassword
    }

    func changePassword(oldPassword: String, newPassword: String) async throws {
        try await Task.sleep(nanoseconds: 500_000_000) // 500ms

        guard isAuthenticated else {
            throw AuthError.notAuthenticated
        }

        guard oldPassword == storedPassword else {
            throw AuthError.invalidCredentials
        }

        guard newPassword.count >= 8 else {
            throw AuthError.passwordTooWeak
        }

        storedPassword = newPassword
    }

    func changePIN(oldPIN: String, newPIN: String) async throws {
        try await Task.sleep(nanoseconds: 500_000_000) // 500ms

        guard isAuthenticated else {
            throw AuthError.notAuthenticated
        }

        guard oldPIN == storedPIN else {
            throw AuthError.invalidPIN
        }

        guard newPIN.count >= 4 else {
            throw AuthError.pinTooShort
        }

        storedPIN = newPIN
    }
}

enum AuthError: Error {
    case invalidCredentials
    case invalidOTP
    case otpExpired
    case sessionExpired
    case userNotFound
    case notAuthenticated
    case invalidEmail
    case invalidToken
    case passwordTooWeak
    case invalidPIN
    case pinTooShort
}
