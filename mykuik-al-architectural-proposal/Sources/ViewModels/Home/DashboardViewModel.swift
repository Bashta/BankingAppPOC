//
//  DashboardViewModel.swift
//  BankingApp
//
//  Stub ViewModel for compilation - to be implemented in future story
//

import Foundation
import Combine

final class DashboardViewModel: ObservableObject {
    private let accountService: AccountServiceProtocol
    private let transactionService: TransactionServiceProtocol
    private let notificationService: NotificationServiceProtocol
    private weak var coordinator: HomeCoordinator?

    init(
        accountService: AccountServiceProtocol,
        transactionService: TransactionServiceProtocol,
        notificationService: NotificationServiceProtocol,
        coordinator: HomeCoordinator
    ) {
        self.accountService = accountService
        self.transactionService = transactionService
        self.notificationService = notificationService
        self.coordinator = coordinator
    }
}
