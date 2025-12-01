//
//  BeneficiaryCell.swift
//  BankingApp
//

import SwiftUI

struct BeneficiaryCell: View {
    let beneficiary: Beneficiary

    var body: some View {
        HStack(spacing: 12) {
            // Leading content
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(beneficiary.name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)

                    if beneficiary.isFavorite {
                        Image(systemName: "star.fill")
                            .font(.caption)
                            .foregroundColor(.yellow)
                    }
                }

                if let bankName = beneficiary.bankName {
                    Text(bankName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Text(beneficiary.accountNumber.maskedAccountNumber)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            // Trailing indicator
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
    }
}
