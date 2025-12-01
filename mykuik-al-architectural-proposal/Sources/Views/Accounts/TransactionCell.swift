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
