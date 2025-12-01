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

#if DEBUG
struct BeneficiaryCell_Previews: PreviewProvider {
    static var previews: some View {
        List {
            BeneficiaryCell(beneficiary: Beneficiary(
                id: "BEN001",
                name: "Jane Smith",
                accountNumber: "9876543210",
                iban: "US12CHAS98765432101234",
                bankName: "Chase Bank",
                type: .external,
                isFavorite: true
            ))

            BeneficiaryCell(beneficiary: Beneficiary(
                id: "BEN002",
                name: "Robert Johnson",
                accountNumber: "5544332211",
                iban: "US12BOFA55443322111234",
                bankName: "Bank of America",
                type: .external,
                isFavorite: false
            ))
        }
        .listStyle(.insetGrouped)
    }
}
#endif
