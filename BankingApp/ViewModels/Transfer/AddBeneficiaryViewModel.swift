//
//  AddBeneficiaryViewModel.swift
//  BankingApp
//
//  Stub ViewModel for compilation - to be implemented in future story
//

import Foundation
import Combine

final class AddBeneficiaryViewModel: ObservableObject {
    private let beneficiaryService: BeneficiaryServiceProtocol
    private weak var coordinator: TransferCoordinator?

    init(
        beneficiaryService: BeneficiaryServiceProtocol,
        coordinator: TransferCoordinator
    ) {
        self.beneficiaryService = beneficiaryService
        self.coordinator = coordinator
    }
}
