import Foundation
import Combine
import OSLog

final class MockAuthService: AuthServiceProtocol {
    // MARK: - Reactive State (AC: #1)

    @Published private(set) var isAuthenticated: Bool = false

    var isAuthenticatedPublisher: AnyPublisher<Bool, Never> {
        $isAuthenticated.eraseToAnyPublisher()
    }

    // MARK: - Session Management (AC: #1, #6)

    private var authToken: AuthToken?
    private var sessionTask: Task<Void, Never>?
    private var cancellables = Set<AnyCancellable>()

    // MARK: - User State

    private var currentUser: User?
    private var storedPassword: String = "password"
    private var storedPIN: String = "1234"

    // Session duration in seconds (30 minutes default, reduced for testing)
    private let sessionDuration: TimeInterval = 1800

    // MARK: - OTP Configuration (AC: #1 - Configurable OTP requirement)

    /// Whether login should require OTP verification (for testing different flows)
    /// Default: false for basic login flow; set to true to test OTP flow
    private(set) var requiresOTPForLogin: Bool = false

    /// Enable OTP requirement for login (for testing)
    func setRequiresOTP(_ requires: Bool) {
        requiresOTPForLogin = requires
    }

    func login(username: String, password: String) async throws -> LoginResult {
        try await Task.sleep(nanoseconds: 500_000_000) // 500ms

        // AC: #2 - Validate credentials
        // For demo: username "user" with password "password" (or "otp" to force OTP flow)
        let validCredentials = (username == "user" && password == storedPassword) ||
                               (username == "otp" && password == "password") // Special OTP test user
        guard validCredentials else {
            throw AuthError.invalidCredentials
        }

        // AC: #1 - Check if OTP is required
        // OTP required if: requiresOTPForLogin is enabled OR username is "otp" (test user)
        let needsOTP = requiresOTPForLogin || username == "otp"

        if needsOTP {
            // Generate OTP reference with 5-minute expiration
            let otpReference = OTPReference(
                id: "OTP-\(UUID().uuidString.prefix(8))",
                expiresAt: Date().addingTimeInterval(300), // 5 minutes
                purpose: .login
            )

            // Store user temporarily (will be activated after OTP verification)
            currentUser = User(
                id: "USER001",
                username: username,
                name: "John Doe",
                email: "user@example.com",
                phoneNumber: "+1234567890",
                address: nil
            )

            // Return result requiring OTP verification
            return LoginResult(
                token: nil,
                requiresOTP: true,
                otpReference: otpReference
            )
        }

        // Direct login (no OTP required)
        // AC: #2 - Set authenticated state on login success
        isAuthenticated = true

        // AC: #2 - Create and store auth token with expiration
        let token = AuthToken(
            accessToken: "mock-token-\(UUID().uuidString)",
            refreshToken: "mock-refresh-\(UUID().uuidString)",
            expiresAt: Date().addingTimeInterval(sessionDuration)
        )
        authToken = token

        currentUser = User(
            id: "USER001",
            username: username,
            name: "John Doe",
            email: "user@example.com",
            phoneNumber: "+1234567890",
            address: nil
        )

        // AC: #6 - Start session timeout
        startSessionTimeout(duration: sessionDuration)

        return LoginResult(
            token: token,
            requiresOTP: false,
            otpReference: nil
        )
    }

    func loginWithBiometric() async throws -> LoginResult {
        Logger.auth.info("Starting biometric login flow")
        try await Task.sleep(nanoseconds: 500_000_000) // 500ms

        // AC: #3 - Set authenticated state on biometric success
        isAuthenticated = true
        Logger.auth.info("Biometric login: authentication state set to true")

        // AC: #3 - Generate and store auth token
        let token = AuthToken(
            accessToken: "mock-biometric-token-\(UUID().uuidString)",
            refreshToken: "mock-refresh-\(UUID().uuidString)",
            expiresAt: Date().addingTimeInterval(sessionDuration)
        )
        authToken = token
        Logger.auth.debug("Biometric login: auth token generated, expires at \(token.expiresAt)")

        currentUser = User(
            id: "USER001",
            username: "user",
            name: "John Doe",
            email: "user@example.com",
            phoneNumber: "+1234567890",
            address: nil
        )
        Logger.auth.debug("Biometric login: user profile loaded")

        // AC: #6 - Start session timeout
        startSessionTimeout(duration: sessionDuration)
        Logger.auth.info("Biometric login: session timer started (duration: \(self.sessionDuration)s)")

        // AC: #3 - Biometric login bypasses OTP requirement
        Logger.auth.info("Biometric login completed successfully")
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

        // AC: #4 - Generate auth token
        let token = AuthToken(
            accessToken: "mock-otp-token-\(UUID().uuidString)",
            refreshToken: "mock-refresh-\(UUID().uuidString)",
            expiresAt: Date().addingTimeInterval(sessionDuration)
        )

        // AC: #4 - Only set isAuthenticated for login purpose
        // For other OTP purposes (transfer, cardAction), user is already logged in
        if reference.purpose == .login {
            isAuthenticated = true
            authToken = token
            startSessionTimeout(duration: sessionDuration)
        }
        // AC: #4 - For transfer, cardPINChange, passwordReset: don't change auth state

        return token
    }

    func logout() async throws {
        try await Task.sleep(nanoseconds: 300_000_000) // 300ms

        // AC: #5 - Clear authentication state
        isAuthenticated = false

        // AC: #5 - Clear auth token
        authToken = nil

        // AC: #5 - Cancel session timeout task to prevent zombie tasks
        sessionTask?.cancel()
        sessionTask = nil

        // AC: #5 - Clear user data (mock secure storage clearing)
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

    // MARK: - Session Timeout (AC: #6)

    /// Starts a background task that expires the session after the specified duration.
    /// Uses Task.sleep for simulation; in production, this would use proper token expiration.
    private func startSessionTimeout(duration: TimeInterval) {
        // Cancel existing session task if running
        sessionTask?.cancel()

        // Create new session timeout task with weak self to prevent retain cycles
        sessionTask = Task { [weak self] in
            do {
                // Sleep for session duration
                try await Task.sleep(nanoseconds: UInt64(duration * 1_000_000_000))

                // Check if task was cancelled during sleep
                guard !Task.isCancelled else { return }

                // Expire session on main actor (UI state updates must be on main thread)
                await MainActor.run {
                    self?.isAuthenticated = false
                    self?.authToken = nil
                }
            } catch {
                // Task was cancelled, no action needed
            }
        }
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
