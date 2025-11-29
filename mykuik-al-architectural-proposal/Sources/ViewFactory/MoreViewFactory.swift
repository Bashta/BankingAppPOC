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

    func makeProfileView(coordinator: MoreCoordinator) -> some View {
        let viewModel = ProfileViewModel(
            authService: dependencyContainer.authService,
            coordinator: coordinator
        )
        return ProfileView(viewModel: viewModel)
    }

    func makeEditProfileView(coordinator: MoreCoordinator) -> some View {
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

    func makeNotificationPreferencesView(coordinator: MoreCoordinator) -> some View {
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

    func makeTermsView(coordinator: MoreCoordinator) -> some View {
        let viewModel = TermsViewModel(
            coordinator: coordinator
        )
        return TermsView(viewModel: viewModel)
    }

    func makePrivacyView(coordinator: MoreCoordinator) -> some View {
        let viewModel = PrivacyViewModel(
            coordinator: coordinator
        )
        return PrivacyView(viewModel: viewModel)
    }
}
