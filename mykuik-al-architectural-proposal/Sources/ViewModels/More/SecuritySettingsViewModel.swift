// SecuritySettingsViewModel.swift
import Foundation
import Combine
final class SecuritySettingsViewModel: ObservableObject {
    private let authService: AuthServiceProtocol
    private let biometricService: BiometricServiceProtocol
    private weak var coordinator: MoreCoordinator?
    init(authService: AuthServiceProtocol, biometricService: BiometricServiceProtocol, coordinator: MoreCoordinator) {
        self.authService = authService
        self.biometricService = biometricService
        self.coordinator = coordinator
    }
}
