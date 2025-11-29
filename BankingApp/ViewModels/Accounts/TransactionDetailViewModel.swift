//
//  TransactionDetailViewModel.swift
//  BankingApp
//
//  Stub ViewModel for compilation - to be implemented in future story
//

import Foundation
import Combine

final class TransactionDetailViewModel: ObservableObject {
    private let transactionId: String
    private let transactionService: TransactionServiceProtocol
    private weak var coordinator: AccountsCoordinator?

    init(
        transactionId: String,
        transactionService: TransactionServiceProtocol,
        coordinator: AccountsCoordinator
    ) {
        self.transactionId = transactionId
        self.transactionService = transactionService
        self.coordinator = coordinator
    }
}
