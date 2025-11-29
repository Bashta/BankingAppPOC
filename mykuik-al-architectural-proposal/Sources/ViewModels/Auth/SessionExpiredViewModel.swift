//
//  SessionExpiredViewModel.swift
//  BankingApp
//
//  ViewModel for the Session Expired screen, displayed when user's session times out.
//  (Story 2.6 AC: #6)
//

import Foundation
import SwiftUI
import Combine

/// ViewModel for SessionExpiredView handling user interaction after session timeout.
///
/// Responsibilities:
/// - Holds weak reference to AuthCoordinator (memory management)
/// - Provides loginAgain() action to dismiss modal and return to login
///
/// Architecture:
/// - Follows MVVM pattern with weak coordinator reference
/// - Delegates ALL navigation to coordinator (never navigates directly)
/// - ViewModel created by AuthViewFactory and passed to SessionExpiredView
///
/// Navigation Flow:
/// - AppCoordinator.sessionExpired() presents this view as fullScreenCover
/// - User taps "Log in Again" → loginAgain() → coordinator.dismiss()
/// - RootView observes isAuthenticated=false, shows AuthCoordinator.rootView()
final class SessionExpiredViewModel: ObservableObject {

    // MARK: - Coordinator Reference

    /// Weak reference to AuthCoordinator to prevent retain cycles (AC: #6)
    /// Memory pattern: ViewModel → weak → Coordinator → strong → ViewFactory
    private weak var coordinator: AuthCoordinator?

    // MARK: - Initialization

    /// Creates SessionExpiredViewModel with coordinator reference.
    ///
    /// - Parameter coordinator: The AuthCoordinator managing this view
    init(coordinator: AuthCoordinator) {
        self.coordinator = coordinator
    }

    // MARK: - Actions

    /// Dismisses the session expired modal and returns to login screen (AC: #6)
    ///
    /// Flow:
    /// 1. Calls coordinator.dismiss() to close fullScreenCover
    /// 2. RootView is already showing AuthCoordinator.rootView() (since isAuthenticated=false)
    /// 3. User sees login screen and can re-authenticate
    ///
    /// Note: No additional navigation needed - RootView conditional rendering
    /// handles the transition based on isAuthenticated state.
    func loginAgain() {
        coordinator?.dismiss()
    }
}
