//
//  StatementDownloadViewModel.swift
//  BankingApp
//
//  Stub ViewModel for compilation - to be implemented in future story
//

import Foundation
import Combine

final class StatementDownloadViewModel: ObservableObject {
    private let accountId: String
    private let month: Int
    private let year: Int
    private let transactionService: TransactionServiceProtocol
    private weak var coordinator: AccountsCoordinator?

    init(
        accountId: String,
        month: Int,
        year: Int,
        transactionService: TransactionServiceProtocol,
        coordinator: AccountsCoordinator
    ) {
        self.accountId = accountId
        self.month = month
        self.year = year
        self.transactionService = transactionService
        self.coordinator = coordinator
    }
}
