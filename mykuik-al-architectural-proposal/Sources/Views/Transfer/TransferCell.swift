//
//  TransferCell.swift
//  BankingApp
//
//  Cell component displaying a single transfer summary with status badge.
//  Story 4.1: Implement Transfer Home Screen
//

import SwiftUI

struct TransferCell: View {
    let transfer: Transfer

    var body: some View {
        HStack(spacing: 12) {
            // Transfer type icon
            Image(systemName: transferIcon)
                .font(.title3)
                .foregroundColor(.blue)
                .frame(width: 40, height: 40)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(8)

            // Destination and date
            VStack(alignment: .leading, spacing: 4) {
                Text(transfer.destinationName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)

                Text(transfer.date.relativeFormatted)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            // Amount and status
            VStack(alignment: .trailing, spacing: 4) {
                Text(transfer.amount.formatted(currency: transfer.currency))
                    .font(.subheadline)
                    .fontWeight(.semibold)

                TransferStatusBadge(status: transfer.status)
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(transfer.destinationName), \(transfer.amount.formatted(currency: transfer.currency)), \(transfer.status.displayName), \(transfer.date.relativeFormatted)")
    }

    private var transferIcon: String {
        switch transfer.type {
        case .internal:
            return "arrow.left.arrow.right"
        case .external, .international:
            return "person.crop.circle"
        }
    }
}

// MARK: - TransferStatusBadge

struct TransferStatusBadge: View {
    let status: TransferStatus

    var body: some View {
        Text(status.displayName)
            .font(.caption2)
            .fontWeight(.medium)
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .background(backgroundColor)
            .foregroundColor(textColor)
            .cornerRadius(4)
    }

    private var backgroundColor: Color {
        switch status {
        case .completed:
            return Color.green.opacity(0.2)
        case .pending, .initiated:
            return Color.yellow.opacity(0.2)
        case .failed, .cancelled:
            return Color.red.opacity(0.2)
        }
    }

    private var textColor: Color {
        switch status {
        case .completed:
            return .green
        case .pending, .initiated:
            return .orange
        case .failed, .cancelled:
            return .red
        }
    }
}

// MARK: - Preview

#Preview("TransferCell - Completed External") {
    TransferCell(
        transfer: Transfer(
            id: "TRF001",
            sourceAccountId: "ACC001",
            destinationType: .beneficiary(beneficiaryId: "BEN001"),
            amount: 250.00,
            currency: "ALL",
            description: "Monthly rent payment",
            reference: "REF00000001",
            status: .completed,
            date: Date().addingTimeInterval(-86400),
            type: .external,
            initiatedDate: Date().addingTimeInterval(-86400),
            completedDate: Date().addingTimeInterval(-86000),
            otpRequired: false,
            otpReference: nil,
            destinationName: "John Smith",
            sourceAccountName: "Primary Checking"
        )
    )
    .background(Color(.systemBackground))
}

#Preview("TransferCell - Pending Internal") {
    TransferCell(
        transfer: Transfer(
            id: "TRF002",
            sourceAccountId: "ACC001",
            destinationType: .internalAccount(accountId: "ACC002"),
            amount: 500.00,
            currency: "ALL",
            description: "Savings deposit",
            reference: "REF00000002",
            status: .pending,
            date: Date().addingTimeInterval(-3600),
            type: .internal,
            initiatedDate: Date().addingTimeInterval(-3600),
            completedDate: nil,
            otpRequired: true,
            otpReference: nil,
            destinationName: "Emergency Savings",
            sourceAccountName: "Primary Checking"
        )
    )
    .background(Color(.systemBackground))
}

#Preview("TransferCell - Failed") {
    TransferCell(
        transfer: Transfer(
            id: "TRF003",
            sourceAccountId: "ACC001",
            destinationType: .beneficiary(beneficiaryId: "BEN002"),
            amount: 75.50,
            currency: "ALL",
            description: "Internet bill",
            reference: "REF00000003",
            status: .failed,
            date: Date().addingTimeInterval(-259200),
            type: .external,
            initiatedDate: Date().addingTimeInterval(-259200),
            completedDate: nil,
            otpRequired: false,
            otpReference: nil,
            destinationName: "ALBtelecom",
            sourceAccountName: "Primary Checking"
        )
    )
    .background(Color(.systemBackground))
}
