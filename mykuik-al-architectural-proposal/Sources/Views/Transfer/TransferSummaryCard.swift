import SwiftUI

struct TransferSummaryCard: View {
    let request: TransferRequest
    let sourceAccount: Account?
    let destinationAccount: Account?
    let beneficiary: Beneficiary?

    var body: some View {
        VStack(spacing: 16) {
            // Transfer Type Badge
            HStack {
                transferTypeBadge
                Spacer()
            }

            Divider()

            // Amount - Prominent Display
            VStack(spacing: 4) {
                Text("Amount")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(request.amount.formatted(currency: request.currency))
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(.primary)
            }

            Divider()

            // From Account
            detailRow(
                label: "From",
                value: sourceAccountName,
                subtitle: sourceAccountNumber
            )

            // To Destination
            detailRow(
                label: "To",
                value: destinationName,
                subtitle: destinationSubtitle
            )

            // Description (if provided)
            if let description = request.description, !description.isEmpty {
                Divider()
                detailRow(
                    label: "Description",
                    value: description,
                    subtitle: nil
                )
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 4)
    }

    // MARK: - Computed Properties

    private var transferTypeBadge: some View {
        Text(request.type == .internal ? "Internal Transfer" : "External Transfer")
            .font(.caption)
            .fontWeight(.medium)
            .padding(.horizontal, 12)
            .padding(.vertical, 4)
            .background(badgeBackgroundColor)
            .foregroundColor(badgeForegroundColor)
            .cornerRadius(12)
    }

    private var badgeBackgroundColor: Color {
        request.type == .internal ? Color.blue.opacity(0.1) : Color.purple.opacity(0.1)
    }

    private var badgeForegroundColor: Color {
        request.type == .internal ? .blue : .purple
    }

    private var sourceAccountName: String {
        sourceAccount?.accountName ?? "Account"
    }

    private var sourceAccountNumber: String {
        sourceAccount?.accountNumber.maskedAccountNumber ?? "****"
    }

    private var destinationName: String {
        if let beneficiary = beneficiary {
            return beneficiary.name
        }
        if let account = destinationAccount {
            return account.accountName
        }
        return "Own Account"
    }

    private var destinationSubtitle: String {
        if let beneficiary = beneficiary {
            let bankName = beneficiary.bankName ?? "Bank"
            return "\(bankName) • \(beneficiary.accountNumber.maskedAccountNumber)"
        }
        if let account = destinationAccount {
            return account.accountNumber.maskedAccountNumber
        }
        if let destId = request.destinationAccountId {
            return "****\(destId.suffix(4))"
        }
        return ""
    }

    // MARK: - Helper Views

    private func detailRow(label: String, value: String, subtitle: String?) -> some View {
        HStack(alignment: .center) {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text(value)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                if let subtitle = subtitle, !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}

// MARK: - Preview

#if DEBUG
struct TransferSummaryCard_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            // Internal Transfer Preview
            TransferSummaryCard(
                request: TransferRequest(
                    type: .internal,
                    sourceAccountId: "ACC001",
                    destinationAccountId: "ACC002",
                    amount: 500.00,
                    currency: "ALL",
                    description: "Monthly savings"
                ),
                sourceAccount: Account(
                    id: "ACC001",
                    accountNumber: "1234567890",
                    accountType: .checking,
                    currency: "ALL",
                    balance: 5000,
                    availableBalance: 5000,
                    accountName: "Primary Checking",
                    iban: nil,
                    isDefault: true
                ),
                destinationAccount: Account(
                    id: "ACC002",
                    accountNumber: "0987654321",
                    accountType: .savings,
                    currency: "ALL",
                    balance: 10000,
                    availableBalance: 10000,
                    accountName: "Emergency Savings",
                    iban: nil,
                    isDefault: false
                ),
                beneficiary: nil
            )

            // External Transfer Preview
            TransferSummaryCard(
                request: TransferRequest(
                    type: .external,
                    sourceAccountId: "ACC001",
                    beneficiaryId: "BEN001",
                    amount: 250.00,
                    currency: "ALL",
                    description: "Rent payment"
                ),
                sourceAccount: Account(
                    id: "ACC001",
                    accountNumber: "1234567890",
                    accountType: .checking,
                    currency: "ALL",
                    balance: 5000,
                    availableBalance: 5000,
                    accountName: "Primary Checking",
                    iban: nil,
                    isDefault: true
                ),
                destinationAccount: nil,
                beneficiary: Beneficiary(
                    id: "BEN001",
                    name: "John Smith",
                    accountNumber: "9876543210",
                    iban: nil,
                    bankName: "Raiffeisen Bank",
                    type: .external,
                    isFavorite: true
                )
            )
        }
        .padding()
        .background(Color(.systemGroupedBackground))
        .previewLayout(.sizeThatFits)
    }
}
#endif
