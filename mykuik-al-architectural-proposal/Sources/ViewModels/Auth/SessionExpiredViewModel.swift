// SessionExpiredViewModel.swift
import Foundation
import Combine
final class SessionExpiredViewModel: ObservableObject {
    private weak var coordinator: AuthCoordinator?
    init(coordinator: AuthCoordinator) {
        self.coordinator = coordinator
    }
}
