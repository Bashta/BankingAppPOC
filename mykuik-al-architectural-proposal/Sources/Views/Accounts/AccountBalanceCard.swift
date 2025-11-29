//
//  AccountBalanceCard.swift
//  BankingApp
//
//  Balance card component displaying account info with toggle visibility.
//  Story 3.2: Implement Account Detail View with Balance Card
//

import SwiftUI

struct AccountBalanceCard: View {
    let account: Account
    let showBalance: Bool
    let onToggle: () -> Void
    var onSetDefault: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header row with name and toggle
            HStack {
                Text(account.accountName)
                    .font(.title2)
                    .fontWeight(.semibold)

                Spacer()

                Button(action: onToggle) {
                    Image(systemName: showBalance ? "eye" : "eye.slash")
                        .foregroundColor(.secondary)
                }
                .accessibilityLabel(showBalance ? "Hide balance" : "Show balance")
            }

            // Account type and masked number
            HStack(spacing: 8) {
                Text(account.accountType.displayName)
                    .font(.caption)
                    .fontWeight(.medium)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.secondary.opacity(0.2))
                    .cornerRadius(4)

                Text(account.accountNumber.maskedAccountNumber)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Divider()

            // Balances
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Current Balance")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(showBalance
                        ? account.balance.formatted(currency: account.currency)
                        : "****")
                        .font(.title)
                        .fontWeight(.bold)
                }

                HStack {
                    Text("Available Balance")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(showBalance
                        ? account.availableBalance.formatted(currency: account.currency)
                        : "****")
                        .font(.headline)
                        .foregroundColor(.green)
                }
            }

            // Set as default button (conditional)
            if !account.isDefault, let onSetDefault = onSetDefault {
                Button(action: onSetDefault) {
                    HStack {
                        Image(systemName: "star")
                        Text("Set as Default Account")
                    }
                    .font(.subheadline)
                }
                .padding(.top, 8)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Preview

#Preview("AccountBalanceCard - Balance Visible") {
    AccountBalanceCard(
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
        showBalance: true,
        onToggle: {}
    )
    .padding()
    .background(Color(.systemGray6))
}

#Preview("AccountBalanceCard - Balance Hidden") {
    AccountBalanceCard(
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
        showBalance: false,
        onToggle: {},
        onSetDefault: {}
    )
    .padding()
    .background(Color(.systemGray6))
}
