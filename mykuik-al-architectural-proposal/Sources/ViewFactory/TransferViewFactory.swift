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

    func makeTransferConfirmationView(transferId: String, coordinator: TransferCoordinator) -> some View {
        let viewModel = TransferConfirmViewModel(
            transferId: transferId,
            transferService: dependencyContainer.transferService,
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

    func makeBeneficiaryListView(coordinator: TransferCoordinator) -> some View {
        let viewModel = BeneficiaryListViewModel(
            beneficiaryService: dependencyContainer.beneficiaryService,
            coordinator: coordinator
        )
        return BeneficiaryListView(viewModel: viewModel)
    }

    func makeAddBeneficiaryView(coordinator: TransferCoordinator) -> some View {
        let viewModel = AddBeneficiaryViewModel(
            beneficiaryService: dependencyContainer.beneficiaryService,
            coordinator: coordinator
        )
        return AddBeneficiaryView(viewModel: viewModel)
    }

    func makeEditBeneficiaryView(beneficiaryId: String, coordinator: TransferCoordinator) -> some View {
        let viewModel = EditBeneficiaryViewModel(
            beneficiaryId: beneficiaryId,
            beneficiaryService: dependencyContainer.beneficiaryService,
            coordinator: coordinator
        )
        return EditBeneficiaryView(viewModel: viewModel)
    }
}
