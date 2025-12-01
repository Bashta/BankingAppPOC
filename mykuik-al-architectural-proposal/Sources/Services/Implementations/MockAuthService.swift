import Foundation
import Combine
import OSLog

final class MockAuthService: AuthServiceProtocol {
    // MARK: - Reactive State (AC: #1)

    @Published private(set) var isAuthenticated: Bool = false

    var isAuthenticatedPublisher: AnyPublisher<Bool, Never> {
        $isAuthenticated.eraseToAnyPublisher()
    }

    // MARK: - Session Management (Story 2.6 AC: #1, #2, #3)
    // Using Timer.scheduledTimer pattern for explicit session timeout handling

    private var authToken: AuthToken?
    private var cancellables = Set<AnyCancellable>()

    /// Tracks when the user last authenticated or performed activity (AC: #1)
    private var lastActivityDate: Date?

    /// Timer for session timeout management (AC: #1)
    /// Fires after sessionTimeout interval to trigger session expiration
    private var sessionTimer: Timer?

    /// Session timeout duration in seconds (AC: #11)
    /// Default: 300 seconds (5 minutes) for POC testing
    /// Production recommendation: 1800 seconds (30 minutes)
    private var sessionTimeout: TimeInterval = 300.0

    // MARK: - User State

    private var currentUser: User?
    private var storedPassword: String = "password"
    private var storedPIN: String = "1234"

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
            expiresAt: Date().addingTimeInterval(sessionTimeout)
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

        // AC: #2 - Start session timer (Story 2.6)
        startSessionTimer()

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
            expiresAt: Date().addingTimeInterval(sessionTimeout)
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

        // AC: #2 - Start session timer (Story 2.6)
        startSessionTimer()
        Logger.auth.info("Biometric login: session timer started (duration: \(self.sessionTimeout)s)")

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
            expiresAt: Date().addingTimeInterval(sessionTimeout)
        )

        // AC: #4 - Only set isAuthenticated for login purpose
        // For other OTP purposes (transfer, cardAction), user is already logged in
        if reference.purpose == .login {
            isAuthenticated = true
            authToken = token
            // AC: #2 - Start session timer (Story 2.6)
            startSessionTimer()
        }
        // AC: #4 - For transfer, cardPINChange, passwordReset: don't change auth state

        // Story 2.10: Commit PIN change after OTP verification
        if reference.purpose == .changePIN {
            commitPINChange()
        }

        return token
    }

    func logout() async throws {
        Logger.auth.info("Logout initiated")
        try await Task.sleep(nanoseconds: 300_000_000) // 300ms

        // Story 2.6 AC: #2 - Stop session timer before clearing auth state
        // Invalidate timer first to prevent race conditions where timer fires during logout
        sessionTimer?.invalidate()
        sessionTimer = nil
        lastActivityDate = nil
        Logger.auth.debug("Session timer invalidated")

        // AC: #5 - Clear authentication state
        isAuthenticated = false
        Logger.auth.debug("Authentication state cleared: isAuthenticated = false")

        // AC: #5 - Clear auth token
        authToken = nil
        Logger.auth.debug("Auth token cleared")

        // AC: #5 - Clear user data (mock secure storage clearing)
        currentUser = nil
        Logger.auth.info("Logout completed - all auth state cleared")
    }

    func forgotPassword(email: String) async throws {
        Logger.auth.debug("[MockAuthService] forgotPassword called for email: \(email.prefix(3))***")

        try await Task.sleep(nanoseconds: 500_000_000) // 500ms

        // Simulate sending reset email
        guard email.contains("@") else {
            Logger.auth.error("[MockAuthService] forgotPassword failed: invalid email format")
            throw AuthError.invalidEmail
        }

        Logger.auth.info("[MockAuthService] forgotPassword: password reset email sent successfully")
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
        Logger.auth.debug("[MockAuthService] changePassword called")
        try await Task.sleep(nanoseconds: 500_000_000) // 500ms

        guard isAuthenticated else {
            Logger.auth.error("[MockAuthService] changePassword failed: not authenticated")
            throw AuthError.notAuthenticated
        }

        guard oldPassword == storedPassword else {
            Logger.auth.error("[MockAuthService] changePassword failed: invalid current password")
            throw AuthError.invalidCredentials
        }

        guard newPassword.count >= 8 else {
            Logger.auth.error("[MockAuthService] changePassword failed: new password too weak (< 8 chars)")
            throw AuthError.passwordTooWeak
        }

        storedPassword = newPassword
        Logger.auth.info("[MockAuthService] changePassword: password changed successfully")
    }

    func changePIN(oldPIN: String, newPIN: String) async throws -> OTPReference {
        Logger.auth.debug("[MockAuthService] changePIN called")
        try await Task.sleep(nanoseconds: 500_000_000) // 500ms

        guard isAuthenticated else {
            Logger.auth.error("[MockAuthService] changePIN failed: not authenticated")
            throw AuthError.notAuthenticated
        }

        // AC #13: Validate oldPIN matches stored PIN (mock: "1234")
        guard oldPIN == storedPIN else {
            Logger.auth.error("[MockAuthService] changePIN failed: invalid current PIN")
            throw AuthError.invalidCredentials
        }

        // AC #13: Validate newPIN is 4 digits numeric
        guard newPIN.count == 4, newPIN.allSatisfy({ $0.isNumber }) else {
            Logger.auth.error("[MockAuthService] changePIN failed: new PIN invalid format (must be 4 digits)")
            throw AuthError.invalidPIN
        }

        // Store new PIN temporarily (will be committed after OTP verification)
        // In production, this would be handled server-side
        pendingNewPIN = newPIN

        Logger.auth.info("[MockAuthService] changePIN: PIN change initiated, OTP required")

        // AC #13: Return OTPReference for verification step
        return OTPReference(
            id: "PIN-CHANGE-\(UUID().uuidString.prefix(8))",
            expiresAt: Date().addingTimeInterval(300), // 5 minutes
            purpose: .changePIN
        )
    }

    /// Pending new PIN waiting for OTP verification
    private var pendingNewPIN: String?

    /// Commits pending PIN change after successful OTP verification
    /// Called internally after verifyOTP succeeds for .changePIN purpose
    func commitPINChange() {
        if let newPIN = pendingNewPIN {
            storedPIN = newPIN
            pendingNewPIN = nil
            Logger.auth.info("[MockAuthService] PIN change committed successfully")
        }
    }

    // MARK: - Session Timeout (Story 2.6 AC: #2, #3)

    /// Starts a session timer that fires after the configured timeout duration (AC: #2)
    ///
    /// Timer Pattern:
    /// - Invalidates any existing timer to prevent duplicates
    /// - Records lastActivityDate for tracking
    /// - Creates Timer.scheduledTimer with sessionTimeout interval
    /// - Timer handler calls handleSessionExpired() when fired
    ///
    /// Called after successful login (password, biometric, or OTP verification)
    private func startSessionTimer() {
        // Invalidate existing timer if any (AC: #2 - prevent duplicate timers)
        sessionTimer?.invalidate()

        // Record activity timestamp (AC: #1)
        lastActivityDate = Date()

        // Schedule new timer on main run loop (AC: #2)
        // Using scheduledTimer ensures timer fires on main thread
        sessionTimer = Timer.scheduledTimer(withTimeInterval: sessionTimeout, repeats: false) { [weak self] _ in
            // Timer fired - session has expired
            // Check if enough time has actually passed (defensive check)
            guard let self = self,
                  let lastActivity = self.lastActivityDate,
                  Date().timeIntervalSince(lastActivity) >= self.sessionTimeout else {
                return
            }

            // Handle expiration on main actor for thread-safe UI updates
            Task { @MainActor in
                self.handleSessionExpired()
            }
        }
    }

    /// Handles session expiration by clearing auth state and notifying observers (AC: #3)
    ///
    /// Called when:
    /// - Session timer fires after timeout interval
    ///
    /// Actions:
    /// 1. Invalidate and clear session timer
    /// 2. Set isAuthenticated = false (triggers AppCoordinator observation)
    /// 3. Clear auth token and user data
    /// 4. Post notification for session expiration event (analytics/logging)
    ///
    /// Note: Production implementation should cancel in-flight network requests.
    /// Mock services have no persistent state to clear. (AC: #9)
    /// TODO: Production enhancement - implement request cancellation
    @MainActor
    private func handleSessionExpired() {
        // Invalidate timer and clear reference (AC: #3)
        sessionTimer?.invalidate()
        sessionTimer = nil

        // Set isAuthenticated = false to trigger auth state observers (AC: #3)
        // This will cause AppCoordinator.observeAuthState() sink to fire
        isAuthenticated = false

        // Clear auth token/credentials (AC: #3)
        authToken = nil
        currentUser = nil
        lastActivityDate = nil

        // Post notification for session expiration event (AC: #3 - optional)
        // Useful for analytics, logging, or other observers
        NotificationCenter.default.post(name: .sessionExpired, object: nil)
    }

    // MARK: - Profile Operations (Story 6.3 AC: #19, #20)

    /// Fetches the current user's profile
    /// - Returns: User object with profile information
    /// - Throws: AuthError.notAuthenticated if user not logged in
    func fetchUserProfile() async throws -> User {
        Logger.auth.debug("[MockAuthService] fetchUserProfile called")
        try await Task.sleep(nanoseconds: 300_000_000) // 300ms delay (AC #20)

        guard isAuthenticated else {
            Logger.auth.error("[MockAuthService] fetchUserProfile failed: not authenticated")
            throw AuthError.notAuthenticated
        }

        // Return current user or create default with full address data
        if let user = currentUser {
            // If user has no address, create one with full mock data
            if user.address == nil {
                let userWithAddress = User(
                    id: user.id,
                    username: user.username,
                    name: user.name,
                    email: user.email,
                    phoneNumber: user.phoneNumber,
                    address: Address(
                        street: "123 Banking Street",
                        city: "Financial City",
                        state: "CA",
                        zipCode: "90210",
                        country: "USA"
                    )
                )
                currentUser = userWithAddress
                Logger.auth.info("[MockAuthService] fetchUserProfile: profile fetched successfully with mock address")
                return userWithAddress
            }
            Logger.auth.info("[MockAuthService] fetchUserProfile: profile fetched successfully")
            return user
        }

        // Create default mock user with realistic data
        let mockUser = User(
            id: "USER001",
            username: "user",
            name: "John Doe",
            email: "john.doe@example.com",
            phoneNumber: "5551234567",
            address: Address(
                street: "123 Banking Street",
                city: "Financial City",
                state: "CA",
                zipCode: "90210",
                country: "USA"
            )
        )
        currentUser = mockUser
        Logger.auth.info("[MockAuthService] fetchUserProfile: created default mock profile")
        return mockUser
    }

    /// Updates the user's profile information
    /// - Parameter user: Updated User object
    /// - Returns: Updated User object (confirms update)
    /// - Throws: AuthError.notAuthenticated if user not logged in
    func updateUserProfile(_ user: User) async throws -> User {
        Logger.auth.debug("[MockAuthService] updateUserProfile called")
        try await Task.sleep(nanoseconds: 500_000_000) // 500ms delay (AC #20)

        guard isAuthenticated else {
            Logger.auth.error("[MockAuthService] updateUserProfile failed: not authenticated")
            throw AuthError.notAuthenticated
        }

        // Store updated user in memory (AC #20)
        currentUser = user
        Logger.auth.info("[MockAuthService] updateUserProfile: profile updated successfully")
        return user
    }

    // MARK: - Deinit

    deinit {
        // Invalidate timer to prevent zombie callbacks
        sessionTimer?.invalidate()
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

// MARK: - Notification Extension for Session Expiration (Story 2.6)

extension Notification.Name {
    /// Posted when user session expires due to timeout
    /// Useful for analytics, logging, or other system observers
    static let sessionExpired = Notification.Name("com.bankingapp.sessionExpired")
}
