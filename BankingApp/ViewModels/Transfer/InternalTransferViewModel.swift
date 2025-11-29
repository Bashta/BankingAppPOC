//
//  InternalTransferViewModel.swift
//  BankingApp
//
//  Stub ViewModel for compilation - to be implemented in future story
//

import Foundation
import Combine

final class InternalTransferViewModel: ObservableObject {
    private let accountService: AccountServiceProtocol
    private let transferService: TransferServiceProtocol
    private let preselectedAccountId: String?
    private weak var coordinator: TransferCoordinator?

    init(
        accountService: AccountServiceProtocol,
        transferService: TransferServiceProtocol,
        preselectedAccountId: String? = nil,
        coordinator: TransferCoordinator
    ) {
        self.accountService = accountService
        self.transferService = transferService
        self.preselectedAccountId = preselectedAccountId
        self.coordinator = coordinator
    }
}
