// ForgotPasswordViewModel.swift
import Foundation
import Combine
final class ForgotPasswordViewModel: ObservableObject {
    private let authService: AuthServiceProtocol
    private weak var coordinator: AuthCoordinator?
    init(authService: AuthServiceProtocol, coordinator: AuthCoordinator) {
        self.authService = authService
        self.coordinator = coordinator
    }
}
