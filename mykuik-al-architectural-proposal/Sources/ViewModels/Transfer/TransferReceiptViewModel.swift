//
//  TransferReceiptViewModel.swift
//  BankingApp
//
//  Stub ViewModel for compilation - to be implemented in future story
//

import Foundation
import Combine

final class TransferReceiptViewModel: ObservableObject {
    private let transferId: String
    private let transferService: TransferServiceProtocol
    private weak var coordinator: TransferCoordinator?

    init(
        transferId: String,
        transferService: TransferServiceProtocol,
        coordinator: TransferCoordinator
    ) {
        self.transferId = transferId
        self.transferService = transferService
        self.coordinator = coordinator
    }
}
