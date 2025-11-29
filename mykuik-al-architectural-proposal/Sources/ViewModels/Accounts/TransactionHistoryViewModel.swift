//
//  TransactionHistoryViewModel.swift
//  BankingApp
//
//  Stub ViewModel for compilation - to be implemented in future story
//

import Foundation
import Combine

final class TransactionHistoryViewModel: ObservableObject {
    private let accountId: String
    private let transactionService: TransactionServiceProtocol
    private weak var coordinator: AccountsCoordinator?

    init(
        accountId: String,
        transactionService: TransactionServiceProtocol,
        coordinator: AccountsCoordinator
    ) {
        self.accountId = accountId
        self.transactionService = transactionService
        self.coordinator = coordinator
    }
}
