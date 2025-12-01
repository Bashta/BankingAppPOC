//
//  HomeViewFactory.swift
//  BankingApp
//
//  View factory for Home feature that creates View+ViewModel pairs
//  with dependency injection for the dashboard and home screens.
//  Story 6.1: Added ViewModel caching pattern (AC: #16)
//

import SwiftUI

// MARK: - HomeViewFactory

/// Factory for creating Home feature views with proper dependency injection.
///
/// Pattern:
/// - Creates ViewModels with services from DependencyContainer
/// - Injects coordinator for navigation
/// - Caches DashboardViewModel to prevent state loss on navigation (AC: #16)
///
/// Caching Rationale:
/// - CRITICAL: Without caching, each navigation triggers new ViewModel creation
/// - This loses loading state, data, and user preferences (balance visibility)
/// - Cache ensures ViewModel persists across tab switches and navigation
final class HomeViewFactory {
    private let dependencyContainer: DependencyContainer

    // MARK: - ViewModel Cache (AC: #16)

    /// Cached DashboardViewModel to preserve state across navigation.
    /// Created on first access, reused until clearCache() is called.
    private var cachedDashboardViewModel: DashboardViewModel?

    // MARK: - Initialization

    init(dependencyContainer: DependencyContainer) {
        self.dependencyContainer = dependencyContainer
    }

    // MARK: - Home Feature Views

    /// Creates or returns cached DashboardView with its ViewModel.
    ///
    /// Caching Pattern (AC: #16):
    /// 1. Check if cachedDashboardViewModel exists
    /// 2. If exists, reuse it (preserves state)
    /// 3. If nil, create new ViewModel and cache it
    /// 4. Return DashboardView with (cached) ViewModel
    ///
    /// - Parameter coordinator: HomeCoordinator for navigation
    /// - Returns: DashboardView with properly initialized ViewModel
    func makeDashboardView(coordinator: HomeCoordinator) -> some View {
        // Return cached ViewModel if available (AC: #16)
        if let cachedViewModel = cachedDashboardViewModel {
            return DashboardView(viewModel: cachedViewModel)
        }

        // Create new ViewModel and cache it
        let viewModel = DashboardViewModel(
            accountService: dependencyContainer.accountService,
            transactionService: dependencyContainer.transactionService,
            notificationService: dependencyContainer.notificationService,
            coordinator: coordinator
        )
        cachedDashboardViewModel = viewModel

        return DashboardView(viewModel: viewModel)
    }

    /// Creates NotificationsView with its ViewModel.
    func makeNotificationsView(coordinator: HomeCoordinator) -> some View {
        let viewModel = NotificationsViewModel(
            notificationService: dependencyContainer.notificationService,
            coordinator: coordinator
        )
        return NotificationsView(viewModel: viewModel)
    }

    /// Creates NotificationDetailView with its ViewModel.
    func makeNotificationDetailView(notificationId: String, coordinator: HomeCoordinator) -> some View {
        let viewModel = NotificationDetailViewModel(
            notificationId: notificationId,
            notificationService: dependencyContainer.notificationService,
            coordinator: coordinator
        )
        return NotificationDetailView(viewModel: viewModel)
    }

    // MARK: - Cache Management (AC: #16)

    /// Clears the cached DashboardViewModel.
    ///
    /// Call this when:
    /// - User logs out (to reset state)
    /// - Session expires
    /// - Need to force fresh data load
    func clearCache() {
        cachedDashboardViewModel = nil
    }
}
