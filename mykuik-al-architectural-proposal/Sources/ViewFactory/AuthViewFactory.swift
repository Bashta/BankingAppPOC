//
//  AuthViewFactory.swift
//  BankingApp
//
//  View factory for Auth feature that creates View+ViewModel pairs
//  for all authentication screens (login, OTP, password management).
//

import SwiftUI

final class AuthViewFactory {
    private let dependencyContainer: DependencyContainer

    init(dependencyContainer: DependencyContainer) {
        self.dependencyContainer = dependencyContainer
    }

    // MARK: - Auth Feature Views

    func makeLoginView(coordinator: AuthCoordinator) -> some View {
        let viewModel = LoginViewModel(
            authService: dependencyContainer.authService,
            biometricService: dependencyContainer.biometricService,
            secureStorage: dependencyContainer.secureStorage,
            coordinator: coordinator
        )
        return LoginView(viewModel: viewModel)
    }

    func makeBiometricLoginView(coordinator: AuthCoordinator) -> some View {
        let viewModel = BiometricLoginViewModel(
            authService: dependencyContainer.authService,
            biometricService: dependencyContainer.biometricService,
            coordinator: coordinator
        )
        return BiometricLoginView(viewModel: viewModel)
    }

    func makeOTPView(otpReference: OTPReference, coordinator: AuthCoordinator) -> some View {
        let viewModel = OTPViewModel(
            otpReference: otpReference,
            authService: dependencyContainer.authService,
            coordinator: coordinator
        )
        return OTPView(viewModel: viewModel)
    }

    func makeOTPVerificationView(otpReference: OTPReference, coordinator: AuthCoordinator) -> some View {
        makeOTPView(otpReference: otpReference, coordinator: coordinator)
    }

    func makeForgotPasswordView(coordinator: AuthCoordinator) -> some View {
        let viewModel = ForgotPasswordViewModel(
            authService: dependencyContainer.authService,
            coordinator: coordinator
        )
        return ForgotPasswordView(viewModel: viewModel)
    }

    func makeResetPasswordView(token: String, coordinator: AuthCoordinator) -> some View {
        let viewModel = ResetPasswordViewModel(
            token: token,
            authService: dependencyContainer.authService,
            coordinator: coordinator
        )
        return ResetPasswordView(viewModel: viewModel)
    }

    // Note: makeChangePasswordView and makeChangePINView are in MoreViewFactory
    // because these flows are accessed from Security Settings in the More tab

    func makeSessionExpiredView(coordinator: AuthCoordinator) -> some View {
        let viewModel = SessionExpiredViewModel(
            coordinator: coordinator
        )
        return SessionExpiredView(viewModel: viewModel)
    }
}
