//
//  InternalTransferView.swift
//  BankingApp
//
//  View for internal transfer flow (transferring between own accounts)
//

import SwiftUI

struct InternalTransferView: View {
    @ObservedObject var viewModel: InternalTransferViewModel

    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.accounts.isEmpty {
                loadingContent
            } else if viewModel.accounts.isEmpty && viewModel.validationError != nil {
                errorContent
            } else {
                transferFormContent
            }
        }
        .navigationTitle("Transfer Between Accounts")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.loadAccounts()
        }
    }

    // MARK: - Loading Content

    @ViewBuilder
    private var loadingContent: some View {
        VStack {
            Spacer()
            ProgressView()
                .scaleEffect(1.2)
            Text("Loading accounts...")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding(.top, 16)
            Spacer()
        }
    }

    // MARK: - Error Content

    @ViewBuilder
    private var errorContent: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundColor(.orange)
            Text(viewModel.validationError ?? "Unable to load accounts")
                .font(.headline)
                .multilineTextAlignment(.center)
            Button("Try Again") {
                Task {
                    await viewModel.loadAccounts()
                }
            }
            .buttonStyle(.bordered)
            Spacer()
        }
        .padding()
    }

    // MARK: - Transfer Form Content

    @ViewBuilder
    private var transferFormContent: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Source Account Section
                sourceAccountSection

                // Destination Account Section
                destinationAccountSection

                // Amount Section
                amountSection

                // Validation Error
                validationErrorSection

                // Description Section
                descriptionSection

                Spacer(minLength: 32)

                // Continue Button
                continueButtonSection
            }
            .padding()
        }
    }

    // MARK: - Source Account Section

    @ViewBuilder
    private var sourceAccountSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            AccountPickerView(
                title: "From Account",
                accounts: viewModel.accounts,
                selectedAccount: Binding(
                    get: { viewModel.sourceAccount },
                    set: { if let account = $0 { viewModel.selectSourceAccount(account) } }
                )
            )

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
                        .foregroundColor(.primary)
                }
                .padding(.horizontal, 4)
            }
        }
    }

    // MARK: - Destination Account Section

    @ViewBuilder
    private var destinationAccountSection: some View {
        AccountPickerView(
            title: "To Account",
            accounts: viewModel.availableDestinationAccounts,
            selectedAccount: Binding(
                get: { viewModel.destinationAccount },
                set: { if let account = $0 { viewModel.selectDestinationAccount(account) } }
            )
        )
    }

    // MARK: - Amount Section

    @ViewBuilder
    private var amountSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Amount")
                .font(.caption)
                .foregroundColor(.secondary)

            AmountInputView(
                amount: $viewModel.amount,
                currency: viewModel.sourceCurrency,
                maximumAmount: viewModel.sourceAvailableBalance
            )
        }
    }

    // MARK: - Validation Error Section

    @ViewBuilder
    private var validationErrorSection: some View {
        if let error = viewModel.validationError,
           error != "Unable to load accounts" {
            HStack {
                Image(systemName: "exclamationmark.circle.fill")
                    .font(.caption)
                Text(error)
                    .font(.caption)
            }
            .foregroundColor(.red)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: - Description Section

    @ViewBuilder
    private var descriptionSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Description")
                .font(.caption)
                .foregroundColor(.secondary)

            TextField("Add a note (optional)", text: $viewModel.transferDescription)
                .textFieldStyle(.roundedBorder)
        }
    }

    // MARK: - Continue Button Section

    @ViewBuilder
    private var continueButtonSection: some View {
        ActionButton(
            title: "Continue",
            isDisabled: !viewModel.isFormValid,
            action: viewModel.proceedToConfirmation
        )
    }
}

// MARK: - Preview

#Preview("InternalTransferView - Loading") {
    NavigationView {
        InternalTransferView(
            viewModel: {
                let vm = InternalTransferViewModel(
                    accountService: MockAccountService(),
                    transferService: MockTransferService(),
                    coordinator: TransferCoordinator(
                        parent: nil,
                        dependencyContainer: DependencyContainer()
                    )
                )
                vm.isLoading = true
                return vm
            }()
        )
    }
    .navigationViewStyle(.stack)
}

#Preview("InternalTransferView - With Accounts") {
    NavigationView {
        InternalTransferView(
            viewModel: {
                let vm = InternalTransferViewModel(
                    accountService: MockAccountService(),
                    transferService: MockTransferService(),
                    coordinator: TransferCoordinator(
                        parent: nil,
                        dependencyContainer: DependencyContainer()
                    )
                )
                vm.accounts = [
                    Account(
                        id: "ACC001",
                        accountNumber: "1234567890",
                        accountType: .checking,
                        currency: "USD",
                        balance: 5432.50,
                        availableBalance: 5232.50,
                        accountName: "Primary Checking",
                        iban: "US12345678901234567890",
                        isDefault: true
                    ),
                    Account(
                        id: "ACC002",
                        accountNumber: "0987654321",
                        accountType: .savings,
                        currency: "USD",
                        balance: 15000.00,
                        availableBalance: 15000.00,
                        accountName: "Emergency Savings",
                        iban: nil,
                        isDefault: false
                    )
                ]
                return vm
            }()
        )
    }
    .navigationViewStyle(.stack)
}

#Preview("InternalTransferView - Pre-selected") {
    NavigationView {
        InternalTransferView(
            viewModel: {
                let vm = InternalTransferViewModel(
                    accountService: MockAccountService(),
                    transferService: MockTransferService(),
                    coordinator: TransferCoordinator(
                        parent: nil,
                        dependencyContainer: DependencyContainer()
                    )
                )
                let accounts = [
                    Account(
                        id: "ACC001",
                        accountNumber: "1234567890",
                        accountType: .checking,
                        currency: "USD",
                        balance: 5432.50,
                        availableBalance: 5232.50,
                        accountName: "Primary Checking",
                        iban: "US12345678901234567890",
                        isDefault: true
                    ),
                    Account(
                        id: "ACC002",
                        accountNumber: "0987654321",
                        accountType: .savings,
                        currency: "USD",
                        balance: 15000.00,
                        availableBalance: 15000.00,
                        accountName: "Emergency Savings",
                        iban: nil,
                        isDefault: false
                    )
                ]
                vm.accounts = accounts
                vm.sourceAccount = accounts[0]
                vm.destinationAccount = accounts[1]
                vm.amount = 100
                return vm
            }()
        )
    }
    .navigationViewStyle(.stack)
}
