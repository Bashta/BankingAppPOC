//
//  ExternalTransferView.swift
//  BankingApp
//
//  View for external transfer flow (transferring to beneficiaries)
//

import SwiftUI

struct ExternalTransferView: View {
    @ObservedObject var viewModel: ExternalTransferViewModel

    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.accounts.isEmpty {
                LoadingView()
            } else {
                transferFormContent
            }
        }
        .navigationTitle("Transfer to Beneficiary")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.loadData()
        }
    }

    // MARK: - Transfer Form Content

    @ViewBuilder
    private var transferFormContent: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Source Account Picker Section
                AccountPickerView(
                    title: "From Account",
                    accounts: viewModel.accounts,
                    selectedAccount: Binding(
                        get: { viewModel.sourceAccount },
                        set: { if let account = $0 { viewModel.selectSourceAccount(account) } }
                    )
                )
                .padding(.horizontal)

                // Available Balance Display
                if let balance = viewModel.sourceAvailableBalance,
                   let source = viewModel.sourceAccount {
                    HStack {
                        Text("Available Balance")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(balance.formatted(currency: source.currency))
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .padding(.horizontal)
                }

                // Beneficiary Picker Section
                BeneficiaryPickerView(
                    beneficiaries: viewModel.sortedBeneficiaries,
                    selectedBeneficiary: Binding(
                        get: { viewModel.selectedBeneficiary },
                        set: { if let beneficiary = $0 { viewModel.selectBeneficiary(beneficiary) } }
                    ),
                    onAddBeneficiary: viewModel.navigateToAddBeneficiary
                )
                .padding(.horizontal)

                // Amount Input Section
                VStack(alignment: .leading, spacing: 8) {
                    Text("Amount")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    AmountInputView(
                        amount: Binding(
                            get: { viewModel.amount },
                            set: { viewModel.updateAmount($0) }
                        ),
                        currency: viewModel.sourceCurrency,
                        maximumAmount: viewModel.sourceAvailableBalance
                    )
                }
                .padding(.horizontal)

                // Validation Error Display
                if let error = viewModel.validationError {
                    HStack {
                        Image(systemName: "exclamationmark.circle.fill")
                            .font(.caption)
                        Text(error)
                            .font(.caption)
                    }
                    .foregroundColor(.red)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                }

                // Description Field
                VStack(alignment: .leading, spacing: 8) {
                    Text("Description")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    TextField("Add a note (optional)", text: $viewModel.transferDescription)
                        .textFieldStyle(.roundedBorder)
                }
                .padding(.horizontal)

                Spacer(minLength: 20)

                // Continue Button
                ActionButton(
                    title: "Continue",
                    isDisabled: !viewModel.isFormValid,
                    action: viewModel.proceedToConfirmation
                )
                .padding(.horizontal)
                .padding(.bottom, 16)
            }
            .padding(.top, 16)
        }
    }
}

// MARK: - Preview

#Preview("ExternalTransferView - Loading") {
    NavigationView {
        ExternalTransferView(
            viewModel: {
                let vm = ExternalTransferViewModel(
                    accountService: MockAccountService(),
                    transferService: MockTransferService(),
                    beneficiaryService: MockBeneficiaryService(),
                    coordinator: TransferCoordinator(parent: nil, dependencyContainer: DependencyContainer())
                )
                return vm
            }()
        )
    }
}
