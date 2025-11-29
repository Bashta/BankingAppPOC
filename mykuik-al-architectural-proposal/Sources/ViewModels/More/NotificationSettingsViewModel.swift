// NotificationSettingsViewModel.swift
import Foundation
import Combine
final class NotificationSettingsViewModel: ObservableObject {
    private let notificationService: NotificationServiceProtocol
    private weak var coordinator: MoreCoordinator?
    init(notificationService: NotificationServiceProtocol, coordinator: MoreCoordinator) {
        self.notificationService = notificationService
        self.coordinator = coordinator
    }
}
