//
//  NotificationDetailViewModel.swift
//  BankingApp
//
//  Stub ViewModel for compilation - to be implemented in future story
//

import Foundation
import Combine

final class NotificationDetailViewModel: ObservableObject {
    private let notificationId: String
    private let notificationService: NotificationServiceProtocol
    private weak var coordinator: HomeCoordinator?

    init(
        notificationId: String,
        notificationService: NotificationServiceProtocol,
        coordinator: HomeCoordinator
    ) {
        self.notificationId = notificationId
        self.notificationService = notificationService
        self.coordinator = coordinator
    }
}
