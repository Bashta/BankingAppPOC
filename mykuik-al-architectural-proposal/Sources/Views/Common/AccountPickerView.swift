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
