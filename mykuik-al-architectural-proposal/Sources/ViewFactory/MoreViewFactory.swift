//
//  MoreViewFactory.swift
//  BankingApp
//
//  View factory for More feature that creates View+ViewModel pairs
//  for profile, settings, and support screens.
//

import SwiftUI

final class MoreViewFactory {
    private let dependencyContainer: DependencyContainer

    // MARK: - Cached ViewModels (Story 6.3 AC: #18)

    /// Cached ProfileViewModel for state persistence across navigation
    private var cachedProfileViewModel: ProfileViewModel?

    init(dependencyContainer: DependencyContainer) {
        self.dependencyContainer = dependencyContainer
    }

    // MARK: - More Feature Views

    func makeMoreMenuView(coordinator: MoreCoordinator) -> some View {
        let viewModel = MoreMenuViewModel(
            coordinator: coordinator
        )
        return MoreMenuView(viewModel: viewModel)
    }

    /// Creates ProfileView with cached ViewModel (AC: #18)
    /// ViewModel is cached for state persistence across navigation
    func makeProfileView(coordinator: MoreCoordinator) -> some View {
        // Return cached ViewModel if exists
        if let cached = cachedProfileViewModel {
            return ProfileView(viewModel: cached)
        }

        // Create new ViewModel and cache it
        let viewModel = ProfileViewModel(
            authService: dependencyContainer.authService,
            coordinator: coordinator
        )
        cachedProfileViewModel = viewModel
        return ProfileView(viewModel: viewModel)
    }

    /// Creates EditProfileView with NEW ViewModel each time (AC: #18)
    /// Form state should reset on each edit session - NO caching
    func makeEditProfileView(coordinator: MoreCoordinator) -> some View {
        // Always create new ViewModel (no caching for form state)
        let viewModel = EditProfileViewModel(
            authService: dependencyContainer.authService,
            coordinator: coordinator
        )
        return EditProfileView(viewModel: viewModel)
    }

    func makeSecuritySettingsView(coordinator: MoreCoordinator) -> some View {
        let viewModel = SecuritySettingsViewModel(
            biometricService: dependencyContainer.biometricService,
            secureStorage: dependencyContainer.secureStorage,
            coordinator: coordinator
        )
        return SecuritySettingsView(viewModel: viewModel)
    }

    func makeChangePasswordView(coordinator: MoreCoordinator) -> some View {
        let viewModel = ChangePasswordViewModel(
            authService: dependencyContainer.authService,
            coordinator: coordinator
        )
        return ChangePasswordView(viewModel: viewModel)
    }

    func makeChangePINView(coordinator: MoreCoordinator) -> some View {
        let viewModel = ChangePINViewModel(
            authService: dependencyContainer.authService,
            coordinator: coordinator
        )
        return ChangePINView(viewModel: viewModel)
    }

    func makeNotificationSettingsView(coordinator: MoreCoordinator) -> some View {
        let viewModel = NotificationSettingsViewModel(
            notificationService: dependencyContainer.notificationService,
            coordinator: coordinator
        )
        return NotificationSettingsView(viewModel: viewModel)
    }

    func makeSupportView(coordinator: MoreCoordinator) -> some View {
        let viewModel = SupportViewModel(
            coordinator: coordinator
        )
        return SupportView(viewModel: viewModel)
    }

    func makeAboutView(coordinator: MoreCoordinator) -> some View {
        let viewModel = AboutViewModel(
            coordinator: coordinator
        )
        return AboutView(viewModel: viewModel)
    }
}
