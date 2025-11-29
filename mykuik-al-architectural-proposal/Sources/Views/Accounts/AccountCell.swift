//
//  AccountCell.swift
//  BankingApp
//
//  Reusable cell component for displaying account information in lists
//

import SwiftUI

struct AccountCell: View {
    let account: Account
    let showBalance: Bool

    var body: some View {
        HStack {
            // Left side: Account info
            VStack(alignment: .leading, spacing: 4) {
                // Account name - prominent
                Text(account.accountName)
                    .font(.headline)
                    .foregroundColor(.primary)

                // Account type badge and masked number
                HStack(spacing: 8) {
                    // Account type badge
                    Text(account.accountType.displayName)
                        .font(.caption)
                        .fontWeight(.medium)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.secondary.opacity(0.15))
                        .foregroundColor(.secondary)
                        .cornerRadius(4)

                    // Masked account number
                    Text(account.accountNumber.maskedAccountNumber)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            // Right side: Balance
            Text(showBalance
                ? account.balance.formatted(currency: account.currency)
                : "****")
                .font(.headline)
                .foregroundColor(showBalance ? .primary : .secondary)
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(account.accountName), \(account.accountType.displayName), \(showBalance ? "balance \(account.balance.formatted(currency: account.currency))" : "balance hidden")")
    }
}

// MARK: - Preview

#Preview("AccountCell - Balance Visible") {
    AccountCell(
        account: Account(
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
        showBalance: true
    )
    .padding()
}

#Preview("AccountCell - Balance Hidden") {
    AccountCell(
        account: Account(
            id: "ACC002",
            accountNumber: "0987654321",
            accountType: .savings,
            currency: "USD",
            balance: 15000.00,
            availableBalance: 15000.00,
            accountName: "Emergency Savings",
            iban: nil,
            isDefault: false
        ),
        showBalance: false
    )
    .padding()
}

#Preview("AccountCell - List") {
    List {
        AccountCell(
            account: Account(
                id: "ACC001",
                accountNumber: "1234567890",
                accountType: .checking,
                currency: "USD",
                balance: 5432.50,
                availableBalance: 5232.50,
                accountName: "Primary Checking",
                iban: nil,
                isDefault: true
            ),
            showBalance: true
        )
        AccountCell(
            account: Account(
                id: "ACC002",
                accountNumber: "0987654321",
                accountType: .savings,
                currency: "USD",
                balance: 15000.00,
                availableBalance: 15000.00,
                accountName: "Emergency Savings",
                iban: nil,
                isDefault: false
            ),
            showBalance: true
        )
    }
}
