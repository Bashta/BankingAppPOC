// AppLogger.swift
// BankingApp
//
// Centralized logging utility using OSLog for structured, performant logging.
// Provides feature-specific loggers with zero runtime cost in release builds.

import OSLog

/// App-wide logger extensions organized by feature/module.
///
/// Usage:
/// ```swift
/// Logger.auth.debug("Login successful")
/// Logger.auth.error("Login failed: \(error.localizedDescription)")
/// Logger.accounts.info("Loaded \(accounts.count) accounts")
/// ```
///
/// Benefits over #if DEBUG print():
/// - Zero overhead in release builds (compiled out)
/// - Structured logging with levels (debug, info, error, fault)
/// - Filterable by subsystem/category in Console.app
/// - Consistent formatting across codebase
/// - Integrates with Xcode console and system logs
///
/// Log Levels:
/// - debug: Detailed info for debugging (not persisted)
/// - info: General information (persisted only during log collect)
/// - error: Error conditions (persisted)
/// - fault: Critical failures (persisted, captures calling context)
extension Logger {

    /// Bundle identifier used as OSLog subsystem
    private static let subsystem = Bundle.main.bundleIdentifier ?? "com.example.BankingApp"

    // MARK: - Feature Loggers

    /// Authentication and session management logging
    static let auth = Logger(subsystem: subsystem, category: "auth")

    /// Account management and balance operations
    static let accounts = Logger(subsystem: subsystem, category: "accounts")

    /// Transfer operations and beneficiary management
    static let transfer = Logger(subsystem: subsystem, category: "transfer")

    /// Card management and controls
    static let cards = Logger(subsystem: subsystem, category: "cards")

    /// Profile, settings, and more menu
    static let more = Logger(subsystem: subsystem, category: "more")

    /// Home/dashboard and notifications
    static let home = Logger(subsystem: subsystem, category: "home")

    // MARK: - Infrastructure Loggers

    /// Service layer and network operations
    static let services = Logger(subsystem: subsystem, category: "services")

    /// Deep link parsing and handling
    static let deepLink = Logger(subsystem: subsystem, category: "deeplink")

    /// Biometric authentication (Face ID / Touch ID)
    static let biometric = Logger(subsystem: subsystem, category: "biometric")
}
