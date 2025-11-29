//
//  TransferHomeViewModel.swift
//  BankingApp
//
//  Stub ViewModel for compilation - to be implemented in future story
//

import Foundation
import Combine

final class TransferHomeViewModel: ObservableObject {
    private let accountService: AccountServiceProtocol
    private let transferService: TransferServiceProtocol
    private weak var coordinator: TransferCoordinator?

    init(
        accountService: AccountServiceProtocol,
        transferService: TransferServiceProtocol,
        coordinator: TransferCoordinator
    ) {
        self.accountService = accountService
        self.transferService = transferService
        self.coordinator = coordinator
    }
}
