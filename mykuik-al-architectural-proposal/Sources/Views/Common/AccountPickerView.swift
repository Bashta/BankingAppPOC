//
//  AccountPickerView.swift
//  BankingApp
//
//  Reusable component for selecting accounts in transfer flows
//

import SwiftUI

struct AccountPickerView: View {
    let title: String
    let accounts: [Account]
    @Binding var selectedAccount: Account?

    @State private var showingPicker = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)

            Button(action: { showingPicker = true }) {
                HStack {
                    if let account = selectedAccount {
                        accountInfo(account)
                    } else {
                        Text("Select an account")
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Image(systemName: "chevron.down")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
            }
            .buttonStyle(.plain)
            .disabled(accounts.isEmpty)
        }
        .sheet(isPresented: $showingPicker) {
            accountPickerSheet
        }
    }

    // MARK: - Account Info View

    @ViewBuilder
    private func accountInfo(_ account: Account) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(account.accountName)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.primary)
            Text("\(account.accountType.displayName) \u{2022} \(account.accountNumber.maskedAccountNumber)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    // MARK: - Account Picker Sheet

    @ViewBuilder
    private var accountPickerSheet: some View {
        NavigationView {
            List(accounts) { account in
                Button(action: {
                    selectedAccount = account
                    showingPicker = false
                }) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(account.accountName)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.primary)
                            Text(account.accountType.displayName)
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(account.accountNumber.maskedAccountNumber)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 4) {
                            Text(account.availableBalance.formatted(currency: account.currency))
                                .font(.subheadline)
                                .fontWeight(.medium)
                            if selectedAccount?.id == account.id {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                                    .font(.caption)
                            }
                        }
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
            .listStyle(.insetGrouped)
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        showingPicker = false
                    }
                }
            }
        }
    }
}

// MARK: - Preview

#Preview("AccountPickerView - Empty") {
    struct PreviewWrapper: View {
        @State private var selectedAccount: Account?

        var body: some View {
            VStack(spacing: 20) {
                AccountPickerView(
                    title: "From Account",
                    accounts: [],
                    selectedAccount: $selectedAccount
                )

                Text("Selected: \(selectedAccount?.accountName ?? "None")")
                    .font(.caption)
            }
            .padding()
        }
    }

    return PreviewWrapper()
}

#Preview("AccountPickerView - With Accounts") {
    struct PreviewWrapper: View {
        @State private var selectedAccount: Account?

        let accounts: [Account] = [
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

        var body: some View {
            VStack(spacing: 20) {
                AccountPickerView(
                    title: "From Account",
                    accounts: accounts,
                    selectedAccount: $selectedAccount
                )

                Text("Selected: \(selectedAccount?.accountName ?? "None")")
                    .font(.caption)
            }
            .padding()
        }
    }

    return PreviewWrapper()
}

#Preview("AccountPickerView - Pre-selected") {
    struct PreviewWrapper: View {
        @State private var selectedAccount: Account? = Account(
            id: "ACC001",
            accountNumber: "1234567890",
            accountType: .checking,
            currency: "USD",
            balance: 5432.50,
            availableBalance: 5232.50,
            accountName: "Primary Checking",
            iban: "US12345678901234567890",
            isDefault: true
        )

        let accounts: [Account] = [
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

        var body: some View {
            VStack(spacing: 20) {
                AccountPickerView(
                    title: "From Account",
                    accounts: accounts,
                    selectedAccount: $selectedAccount
                )

                Text("Selected: \(selectedAccount?.accountName ?? "None")")
                    .font(.caption)
            }
            .padding()
        }
    }

    return PreviewWrapper()
}
