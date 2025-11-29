//
//  NotificationsViewModel.swift
//  BankingApp
//
//  Stub ViewModel for compilation - to be implemented in future story
//

import Foundation
import Combine

final class NotificationsViewModel: ObservableObject {
    private let notificationService: NotificationServiceProtocol
    private weak var coordinator: HomeCoordinator?

    init(
        notificationService: NotificationServiceProtocol,
        coordinator: HomeCoordinator
    ) {
        self.notificationService = notificationService
        self.coordinator = coordinator
    }
}
