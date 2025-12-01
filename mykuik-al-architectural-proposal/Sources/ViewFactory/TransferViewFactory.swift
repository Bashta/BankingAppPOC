//
//  TransferViewFactory.swift
//  BankingApp
//
//  View factory for Transfer feature that creates View+ViewModel pairs
//  for all transfer and beneficiary management screens.
//

import SwiftUI

final class TransferViewFactory {
    private let dependencyContainer: DependencyContainer

    init(dependencyContainer: DependencyContainer) {
        self.dependencyContainer = dependencyContainer
    }

    // MARK: - Transfer Feature Views

    func makeTransferHomeView(coordinator: TransferCoordinator) -> some View {
        let viewModel = TransferHomeViewModel(
            transferService: dependencyContainer.transferService,
            beneficiaryService: dependencyContainer.beneficiaryService,
            coordinator: coordinator
        )
        return TransferHomeView(viewModel: viewModel)
    }

    func makeInternalTransferView(coordinator: TransferCoordinator) -> some View {
        let viewModel = InternalTransferViewModel(
            accountService: dependencyContainer.accountService,
            transferService: dependencyContainer.transferService,
            coordinator: coordinator
        )
        return InternalTransferView(viewModel: viewModel)
    }

    func makeInternalTransferWithAccountView(fromAccountId: String, coordinator: TransferCoordinator) -> some View {
        let viewModel = InternalTransferViewModel(
            accountService: dependencyContainer.accountService,
            transferService: dependencyContainer.transferService,
            preselectedAccountId: fromAccountId,
            coordinator: coordinator
        )
        return InternalTransferView(viewModel: viewModel)
    }

    func makeExternalTransferView(coordinator: TransferCoordinator) -> some View {
        let viewModel = ExternalTransferViewModel(
            accountService: dependencyContainer.accountService,
            transferService: dependencyContainer.transferService,
            beneficiaryService: dependencyContainer.beneficiaryService,
            coordinator: coordinator
        )
        return ExternalTransferView(viewModel: viewModel)
    }

    func makeTransferConfirmView(request: TransferRequest, coordinator: TransferCoordinator) -> some View {
        let viewModel = TransferConfirmViewModel(
            transferRequest: request,
            transferService: dependencyContainer.transferService,
            accountService: dependencyContainer.accountService,
            beneficiaryService: dependencyContainer.beneficiaryService,
            coordinator: coordinator
        )
        return TransferConfirmView(viewModel: viewModel)
    }

    func makeTransferReceiptView(transferId: String, coordinator: TransferCoordinator) -> some View {
        let viewModel = TransferReceiptViewModel(
            transferId: transferId,
            transferService: dependencyContainer.transferService,
            coordinator: coordinator
        )
        return TransferReceiptView(viewModel: viewModel)
    }

    func makeAddBeneficiaryView(coordinator: TransferCoordinator, beneficiary: Beneficiary? = nil) -> some View {
        let viewModel = AddBeneficiaryViewModel(
            beneficiaryService: dependencyContainer.beneficiaryService,
            coordinator: coordinator,
            existingBeneficiary: beneficiary
        )
        return AddBeneficiaryView(viewModel: viewModel)
    }

    func makeEditBeneficiaryView(coordinator: TransferCoordinator, beneficiary: Beneficiary?) -> some View {
        // Use AddBeneficiaryView in edit mode with the beneficiary
        let viewModel = AddBeneficiaryViewModel(
            beneficiaryService: dependencyContainer.beneficiaryService,
            coordinator: coordinator,
            existingBeneficiary: beneficiary
        )
        return AddBeneficiaryView(viewModel: viewModel)
    }
}
