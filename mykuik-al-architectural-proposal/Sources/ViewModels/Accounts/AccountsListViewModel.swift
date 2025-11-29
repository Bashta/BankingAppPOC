//
//  AccountsListViewModel.swift
//  BankingApp
//
//  Stub ViewModel for compilation - to be implemented in future story
//

import Foundation
import Combine

final class AccountsListViewModel: ObservableObject {
    private let accountService: AccountServiceProtocol
    private weak var coordinator: AccountsCoordinator?

    init(
        accountService: AccountServiceProtocol,
        coordinator: AccountsCoordinator
    ) {
        self.accountService = accountService
        self.coordinator = coordinator
    }
}
