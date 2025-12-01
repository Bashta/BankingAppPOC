//
//  AccountSummaryCard.swift
//  BankingApp
//
//  Compact account summary card for dashboard horizontal scroll.
//  Story 6.1: Implement Dashboard View with Account Summaries
//

import SwiftUI

// MARK: - AccountSummaryCard (AC: #11)

/// Compact card displaying account summary information for dashboard.
///
/// Features:
/// - Account name and type
/// - Masked account number (last 4 digits)
/// - Balance (or masked when hidden)
/// - Optional mini transfer button
/// - Tap gesture for navigation
///
/// Usage:
/// ```swift
/// AccountSummaryCard(
///     account: account,
///     showBalance: viewModel.showBalance,
///     onTap: { viewModel.showAccountDetail(account) }
/// )
/// ```
struct AccountSummaryCard: View {
    /// The account to display
    let account: Account

    /// Whether to show or mask the balance
    let showBalance: Bool

    /// Action when card is tapped
    let onTap: () -> Void

    /// Optional action for mini transfer button
    let onTransferTap: (() -> Void)?

    // MARK: - Initialization

    init(
        account: Account,
        showBalance: Bool,
        onTap: @escaping () -> Void,
        onTransferTap: (() -> Void)? = nil
    ) {
        self.account = account
        self.showBalance = showBalance
        self.onTap = onTap
        self.onTransferTap = onTransferTap
    }

    // MARK: - Body

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                // Account Type Badge
                accountTypeBadge

                // Account Name
                Text(account.accountName)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                    .lineLimit(1)

                // Masked Account Number
                Text(account.accountNumber.maskedAccountNumber)
                    .font(.caption)
                    .foregroundColor(.secondary)

                Spacer(minLength: 4)

                // Balance
                balanceView

                // Optional Transfer Button
                if onTransferTap != nil {
                    miniTransferButton
                }
            }
            .padding(12)
            .frame(width: 160, height: onTransferTap != nil ? 150 : 130)
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityDescription)
        .accessibilityHint("Double tap to view account details")
    }

    // MARK: - Subviews

    /// Account type badge
    private var accountTypeBadge: some View {
        Text(account.accountType.displayName)
            .font(.caption2)
            .fontWeight(.medium)
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(badgeColor)
            .cornerRadius(4)
    }

    /// Balance display with masking support
    private var balanceView: some View {
        Group {
            if showBalance {
                Text(account.balance.formatted(currency: account.currency))
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
            } else {
                Text("****")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
            }
        }
        .lineLimit(1)
        .minimumScaleFactor(0.8)
    }

    /// Mini transfer button
    private var miniTransferButton: some View {
        Button(action: {
            onTransferTap?()
        }) {
            HStack(spacing: 4) {
                Image(systemName: "arrow.left.arrow.right")
                    .font(.caption2)
                Text("Transfer")
                    .font(.caption2)
            }
            .foregroundColor(.accentColor)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.accentColor.opacity(0.1))
            .cornerRadius(4)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Transfer from this account")
    }

    // MARK: - Helpers

    /// Badge color based on account type
    private var badgeColor: Color {
        switch account.accountType {
        case .checking:
            return .blue
        case .savings:
            return .green
        case .deposit:
            return .orange
        case .loan:
            return .red
        }
    }

    /// Accessibility description
    private var accessibilityDescription: String {
        let balanceText = showBalance
            ? account.balance.formatted(currency: account.currency)
            : "Balance hidden"
        return "\(account.accountName), \(account.accountType.displayName) account, ending in \(String(account.accountNumber.suffix(4))), \(balanceText)"
    }
}
