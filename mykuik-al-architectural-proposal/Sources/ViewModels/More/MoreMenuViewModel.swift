// MoreMenuViewModel.swift
// Story 2.11: Implement Logout with State Clearing

import Foundation
import Combine
import OSLog

/// ViewModel for the More Menu screen.
///
/// Responsibilities:
/// - Navigate to profile, security, notifications, support, about screens
/// - Handle logout flow with optional confirmation
///
/// Story 2.11 AC: #2 - Logout Implementation:
/// - showLogoutConfirmation: Published property for alert binding
/// - confirmLogout(): Shows confirmation alert
/// - cancelLogout(): Dismisses alert without logging out
/// - logout(): Proceeds with logout via coordinator
final class MoreMenuViewModel: ObservableObject {

    // MARK: - Published Properties

    /// Controls the logout confirmation alert visibility (Story 2.11 AC: #2)
    @Published var showLogoutConfirmation = false

    // MARK: - Dependencies

    /// Weak reference to coordinator to prevent retain cycles
    private weak var coordinator: MoreCoordinator?

    // MARK: - Initialization

    init(coordinator: MoreCoordinator) {
        self.coordinator = coordinator
    }

    // MARK: - Navigation Actions

    /// Navigate to Profile screen
    func navigateToProfile() {
        coordinator?.push(.profile)
    }

    /// Navigate to Security Settings screen
    func navigateToSecurity() {
        coordinator?.push(.security)
    }

    /// Navigate to Notification Settings screen
    func navigateToNotificationSettings() {
        coordinator?.push(.notificationSettings)
    }

    /// Navigate to Support screen
    func navigateToSupport() {
        coordinator?.push(.support)
    }

    /// Navigate to About screen
    func navigateToAbout() {
        coordinator?.push(.about)
    }

    // MARK: - Logout Actions (Story 2.11 AC: #2)

    /// Shows the logout confirmation alert.
    /// Called when user taps the Logout button in MoreMenuView.
    func confirmLogout() {
        showLogoutConfirmation = true
        Logger.auth.debug("Logout confirmation requested")
    }

    /// Cancels the logout flow and dismisses the confirmation alert.
    /// Called when user taps "Cancel" in the logout alert.
    func cancelLogout() {
        showLogoutConfirmation = false
        Logger.auth.debug("Logout cancelled by user")
    }

    /// Proceeds with logout by delegating to coordinator.
    /// Called when user taps "Logout" (confirm) in the logout alert.
    ///
    /// Flow:
    /// 1. Dismiss confirmation alert
    /// 2. Call coordinator.requestLogout()
    /// 3. Coordinator delegates to AppCoordinator.logout()
    /// 4. AuthService clears state → RootView shows LoginView
    func logout() {
        showLogoutConfirmation = false
        coordinator?.requestLogout()
        Logger.auth.info("Logout requested from MoreMenuViewModel")
    }
}
