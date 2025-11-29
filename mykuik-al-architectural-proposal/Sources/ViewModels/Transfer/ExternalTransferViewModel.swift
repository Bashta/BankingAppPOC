//
//  ExternalTransferViewModel.swift
//  BankingApp
//
//  Stub ViewModel for compilation - to be implemented in future story
//

import Foundation
import Combine

final class ExternalTransferViewModel: ObservableObject {
    private let accountService: AccountServiceProtocol
    private let transferService: TransferServiceProtocol
    private let beneficiaryService: BeneficiaryServiceProtocol
    private weak var coordinator: TransferCoordinator?

    init(
        accountService: AccountServiceProtocol,
        transferService: TransferServiceProtocol,
        beneficiaryService: BeneficiaryServiceProtocol,
        coordinator: TransferCoordinator
    ) {
        self.accountService = accountService
        self.transferService = transferService
        self.beneficiaryService = beneficiaryService
        self.coordinator = coordinator
    }
}
