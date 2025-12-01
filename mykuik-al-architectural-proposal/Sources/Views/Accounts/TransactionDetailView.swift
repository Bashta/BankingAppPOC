//
//  TransactionDetailView.swift
//  BankingApp
//
//  View for displaying comprehensive transaction details.
//  Story 3.4: Implement Transaction Detail View
//

import SwiftUI

struct TransactionDetailView: View {
    @ObservedObject var viewModel: TransactionDetailViewModel

    var body: some View {
        Group {
            if let transaction = viewModel.transaction {
                content(transaction: transaction)
            } else if viewModel.error != nil {
                ErrorView(
                    message: "Unable to load transaction details",
                    retryAction: { Task { await viewModel.loadData() } }
                )
            } else {
                // Initial loading state or loading in progress
                LoadingView(message: "Loading transaction...")
            }
        }
        .navigationTitle("Transaction Details")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.loadData()
        }
    }

    // MARK: - Content View

    private func content(transaction: Transaction) -> some View {
        ScrollView {
            VStack(spacing: 24) {
                // Amount Header
                amountHeader(transaction: transaction)

                // Status Badge
                statusBadge(status: transaction.status)

                // Transaction Details Card
                transactionDetailsCard(transaction: transaction)

                // Account Info Section
                accountInfoSection(transaction: transaction)
            }
            .padding()
        }
        .refreshable {
            await viewModel.refresh()
        }
    }

    // MARK: - Amount Header (AC: #5)

    private func amountHeader(transaction: Transaction) -> some View {
        VStack(spacing: 8) {
            Text("\(transaction.type.amountPrefix)\(transaction.amount.formatted(currency: transaction.currency))")
                .font(.system(size: 36, weight: .bold))
                .foregroundColor(transaction.type.amountColor)

            Text(transaction.type.rawValue.capitalized)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 8)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(transaction.type.rawValue) of \(transaction.amount.formatted(currency: transaction.currency))")
    }

    // MARK: - Status Badge (AC: #6)

    private func statusBadge(status: TransactionStatus) -> some View {
        Text(status.rawValue.capitalized)
            .font(.caption)
            .fontWeight(.semibold)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(statusColor(status).opacity(0.15))
            .foregroundColor(statusColor(status))
            .clipShape(Capsule())
            .accessibilityLabel("Status: \(status.rawValue)")
    }

    private func statusColor(_ status: TransactionStatus) -> Color {
        switch status {
        case .completed:
            return .green
        case .pending:
            return .orange
        case .failed:
            return .red
        case .cancelled:
            return .gray
        }
    }

    // MARK: - Transaction Details Card (AC: #7)

    private func transactionDetailsCard(transaction: Transaction) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            // Section Header
            Text("Details")
                .font(.headline)
                .foregroundColor(.primary)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)

            Divider()

            // Type Row
            detailRow(label: "Type", value: transaction.type.rawValue.capitalized)

            // Category Row with Icon
            detailRowWithIcon(
                label: "Category",
                value: transaction.category.rawValue.capitalized,
                icon: transaction.category.icon
            )

            // Description Row
            detailRow(label: "Description", value: transaction.description)

            // Merchant Row (if available)
            if let merchant = transaction.merchantName {
                detailRow(label: "Merchant", value: merchant)
            }

            // Date and Time Row
            detailRow(label: "Date & Time", value: transaction.date.fullDateTimeString())

            // Reference Row (if available)
            if let reference = transaction.reference {
                detailRow(label: "Reference", value: reference, isLast: transaction.balance == nil)
            }

            // Balance After Row (if available)
            if let balance = transaction.balance {
                detailRow(
                    label: "Balance After",
                    value: balance.formatted(currency: transaction.currency),
                    isLast: true
                )
            }
        }
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
    }

    // MARK: - Account Info Section (AC: #8)

    private func accountInfoSection(transaction: Transaction) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            // Section Header
            Text("Account")
                .font(.headline)
                .foregroundColor(.primary)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)

            Divider()

            // Account Name Row (if available)
            if let accountName = transaction.accountName {
                detailRow(label: "Account Name", value: accountName)
            }

            // Account Number Row (masked)
            detailRow(label: "Account Number", value: transaction.accountId.maskedAccountNumber, isLast: true)
        }
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
    }

    // MARK: - Detail Row Helpers

    private func detailRow(label: String, value: String, isLast: Bool = false) -> some View {
        VStack(spacing: 0) {
            HStack {
                Text(label)
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Spacer()

                Text(value)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.trailing)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            if !isLast {
                Divider()
                    .padding(.leading, 16)
            }
        }
    }

    private func detailRowWithIcon(label: String, value: String, icon: String, isLast: Bool = false) -> some View {
        VStack(spacing: 0) {
            HStack {
                Text(label)
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Spacer()

                HStack(spacing: 6) {
                    Image(systemName: icon)
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    Text(value)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            if !isLast {
                Divider()
                    .padding(.leading, 16)
            }
        }
    }
}
