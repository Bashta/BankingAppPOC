// ResetPasswordViewModel.swift
import Foundation
import Combine
final class ResetPasswordViewModel: ObservableObject {
    private let token: String
    private let authService: AuthServiceProtocol
    private weak var coordinator: AuthCoordinator?
    init(token: String, authService: AuthServiceProtocol, coordinator: AuthCoordinator) {
        self.token = token
        self.authService = authService
        self.coordinator = coordinator
    }
}
