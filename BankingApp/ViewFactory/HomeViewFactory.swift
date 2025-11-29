//
//  HomeViewFactory.swift
//  BankingApp
//
//  View factory for Home feature that creates View+ViewModel pairs
//  with dependency injection for the dashboard and home screens.
//

import SwiftUI

final class HomeViewFactory {
    private let dependencyContainer: DependencyContainer

    init(dependencyContainer: DependencyContainer) {
        self.dependencyContainer = dependencyContainer
    }

    // MARK: - Home Feature Views

    func makeDashboardView(coordinator: HomeCoordinator) -> some View {
        let viewModel = DashboardViewModel(
            accountService: dependencyContainer.accountService,
            transactionService: dependencyContainer.transactionService,
            notificationService: dependencyContainer.notificationService,
            coordinator: coordinator
        )
        return DashboardView(viewModel: viewModel)
    }

    func makeNotificationsView(coordinator: HomeCoordinator) -> some View {
        let viewModel = NotificationsViewModel(
            notificationService: dependencyContainer.notificationService,
            coordinator: coordinator
        )
        return NotificationsView(viewModel: viewModel)
    }

    func makeNotificationDetailView(notificationId: String, coordinator: HomeCoordinator) -> some View {
        let viewModel = NotificationDetailViewModel(
            notificationId: notificationId,
            notificationService: dependencyContainer.notificationService,
            coordinator: coordinator
        )
        return NotificationDetailView(viewModel: viewModel)
    }
}
