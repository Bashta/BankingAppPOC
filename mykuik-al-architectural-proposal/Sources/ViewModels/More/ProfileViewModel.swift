// ProfileViewModel.swift
import Foundation
import Combine
final class ProfileViewModel: ObservableObject {
    private let authService: AuthServiceProtocol
    private weak var coordinator: MoreCoordinator?
    init(authService: AuthServiceProtocol, coordinator: MoreCoordinator) {
        self.authService = authService
        self.coordinator = coordinator
    }
}
