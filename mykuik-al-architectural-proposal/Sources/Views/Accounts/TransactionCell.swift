//
//  TransactionCell.swift
//  BankingApp
//
//  Cell component displaying a single transaction summary.
//  Story 3.2: Implement Account Detail View with Balance Card
//

import SwiftUI

struct TransactionCell: View {
    let transaction: Transaction

    var body: some View {
        HStack(spacing: 12) {
            // Category icon
            Image(systemName: transaction.category.icon)
                .font(.title3)
                .foregroundColor(.secondary)
                .frame(width: 40, height: 40)
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(8)

            // Description and date
            VStack(alignment: .leading, spacing: 4) {
                Text(transaction.description)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)

                Text(transaction.date.relativeFormatted)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            // Amount with color
            Text("\(transaction.type.amountPrefix)\(transaction.amount.formatted(currency: transaction.currency))")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(transaction.type.amountColor)
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(transaction.description), \(transaction.type.amountPrefix)\(transaction.amount.formatted(currency: transaction.currency)), \(transaction.date.relativeFormatted)")
    }
}

// MARK: - Preview

#Preview("TransactionCell - Debit") {
    TransactionCell(
        transaction: Transaction(
            id: "TXN001",
            accountId: "ACC001",
            type: .debit,
            amount: 45.99,
            currency: "USD",
            description: "Amazon Purchase",
            merchantName: "Amazon",
            category: .purchase,
            date: Date().addingTimeInterval(-86400),
            status: .completed,
            reference: "AMZ12345",
            balance: 5386.51
        )
    )
    .padding()
}

#Preview("TransactionCell - Credit") {
    TransactionCell(
        transaction: Transaction(
            id: "TXN002",
            accountId: "ACC001",
            type: .credit,
            amount: 3500.00,
            currency: "USD",
            description: "Salary Deposit",
            merchantName: nil,
            category: .salary,
            date: Date().addingTimeInterval(-172800),
            status: .completed,
            reference: "SAL67890",
            balance: 5432.50
        )
    )
    .padding()
}

#Preview("TransactionCell - Transfer") {
    TransactionCell(
        transaction: Transaction(
            id: "TXN003",
            accountId: "ACC001",
            type: .debit,
            amount: 500.00,
            currency: "USD",
            description: "Transfer to Savings",
            merchantName: nil,
            category: .transfer,
            date: Date(),
            status: .completed,
            reference: nil,
            balance: 4500.00
        )
    )
    .padding()
}
