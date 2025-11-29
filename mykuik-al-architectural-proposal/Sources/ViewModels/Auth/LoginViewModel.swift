// LoginViewModel.swift
import Foundation
import Combine
final class LoginViewModel: ObservableObject {
    private let authService: AuthServiceProtocol
    private let biometricService: BiometricServiceProtocol
    private weak var coordinator: AuthCoordinator?
    init(authService: AuthServiceProtocol, biometricService: BiometricServiceProtocol, coordinator: AuthCoordinator) {
        self.authService = authService
        self.biometricService = biometricService
        self.coordinator = coordinator
    }
}
