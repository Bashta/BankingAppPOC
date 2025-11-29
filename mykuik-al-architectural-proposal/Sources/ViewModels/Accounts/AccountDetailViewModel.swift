//
//  AccountDetailViewModel.swift
//  BankingApp
//
//  Stub ViewModel for compilation - to be implemented in future story
//

import Foundation
import Combine

final class AccountDetailViewModel: ObservableObject {
    private let accountId: String
    private let accountService: AccountServiceProtocol
    private let transactionService: TransactionServiceProtocol
    private weak var coordinator: AccountsCoordinator?

    init(
        accountId: String,
        accountService: AccountServiceProtocol,
        transactionService: TransactionServiceProtocol,
        coordinator: AccountsCoordinator
    ) {
        self.accountId = accountId
        self.accountService = accountService
        self.transactionService = transactionService
        self.coordinator = coordinator
    }
}
