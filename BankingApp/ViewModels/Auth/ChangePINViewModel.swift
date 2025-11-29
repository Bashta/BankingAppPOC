// ChangePINViewModel.swift
import Foundation
import Combine
final class ChangePINViewModel: ObservableObject {
    private let authService: AuthServiceProtocol
    private weak var authCoordinator: AuthCoordinator?
    private weak var moreCoordinator: MoreCoordinator?

    init(authService: AuthServiceProtocol, coordinator: AuthCoordinator) {
        self.authService = authService
        self.authCoordinator = coordinator
    }

    init(authService: AuthServiceProtocol, coordinator: MoreCoordinator) {
        self.authService = authService
        self.moreCoordinator = coordinator
    }
}
