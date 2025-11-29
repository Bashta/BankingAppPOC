//
//  EditBeneficiaryViewModel.swift
//  BankingApp
//
//  Stub ViewModel for compilation - to be implemented in future story
//

import Foundation
import Combine

final class EditBeneficiaryViewModel: ObservableObject {
    private let beneficiaryId: String
    private let beneficiaryService: BeneficiaryServiceProtocol
    private weak var coordinator: TransferCoordinator?

    init(
        beneficiaryId: String,
        beneficiaryService: BeneficiaryServiceProtocol,
        coordinator: TransferCoordinator
    ) {
        self.beneficiaryId = beneficiaryId
        self.beneficiaryService = beneficiaryService
        self.coordinator = coordinator
    }
}
