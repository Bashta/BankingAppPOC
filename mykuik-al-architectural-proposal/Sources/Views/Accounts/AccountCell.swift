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
