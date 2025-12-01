//
//  CardDetailView.swift
//  BankingApp
//
//  View displaying card details with linked account, quick actions,
//  and recent transactions.
//  Story 5.2: Implement Card Detail View
//

import SwiftUI

struct CardDetailView: View {
    @ObservedObject var viewModel: CardDetailViewModel

    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.card == nil {
                LoadingView()
            } else if let card = viewModel.card {
                content(card: card)
            } else if viewModel.error != nil {
                ErrorView(
                    message: "Unable to load card details",
                    retryAction: { Task { await viewModel.loadData() } }
                )
            } else {
                // Initial state before loading
                LoadingView()
            }
        }
        .navigationTitle("Card Details")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.loadData()
        }
        .refreshable {
            await viewModel.refresh()
        }
    }

    // MARK: - Content

    private func content(card: Card) -> some View {
        ScrollView {
            VStack(spacing: 20) {
                // Visual Card
                CardView(card: card)
                    .padding(.horizontal)

                // Card Details Section
                cardDetailsSection(card: card)

                // Linked Account Section
                if let account = viewModel.linkedAccount {
                    linkedAccountSection(account: account)
                }

                // Quick Actions Section
                quickActionsSection(card: card)

                // Recent Transactions Section
                recentTransactionsSection
            }
            .padding(.vertical)
        }
    }

    // MARK: - Card Details Section

    private func cardDetailsSection(card: Card) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader("Card Information")

            VStack(spacing: 0) {
                detailRow(label: "Card Holder", value: card.cardholderName)
                Divider()
                detailRow(label: "Card Number", value: card.cardNumber.maskedCardNumber)
                Divider()
                detailRow(label: "Expiry Date", value: formattedExpiry(month: card.expiryMonth, year: card.expiryYear))
                Divider()
                detailRow(label: "CVV", value: "***")
                Divider()
                detailRow(label: "Card Type", value: card.cardType.displayName)
                Divider()
                detailRow(label: "Card Brand", value: card.cardBrand.displayName)
                Divider()
                HStack {
                    Text("Status")
                        .foregroundColor(.secondary)
                    Spacer()
                    StatusBadge(cardStatus: card.status)
                }
                .padding(.vertical, 12)
                .padding(.horizontal, 16)
            }
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
        }
        .padding(.horizontal)
    }

    // MARK: - Linked Account Section

    private func linkedAccountSection(account: Account) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader("Linked Account")

            VStack(spacing: 0) {
                detailRow(label: "Account Name", value: account.accountName)
                Divider()
                detailRow(label: "Account Number", value: account.accountNumber.maskedAccountNumber)
                Divider()
                HStack {
                    Text("Available Balance")
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(account.availableBalance.formatted(currency: account.currency))
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                }
                .padding(.vertical, 12)
                .padding(.horizontal, 16)
            }
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
        }
        .padding(.horizontal)
    }

    // MARK: - Quick Actions Section

    private func quickActionsSection(card: Card) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader("Quick Actions")

            VStack(spacing: 12) {
                // Settings button - always visible
                quickActionButton(
                    icon: "gearshape",
                    title: "Card Settings",
                    subtitle: "Manage card preferences",
                    style: .standard,
                    action: viewModel.showSettings
                )

                // Limits button - always visible
                quickActionButton(
                    icon: "chart.bar",
                    title: "Spending Limits",
                    subtitle: "View and manage limits",
                    style: .standard,
                    action: viewModel.showLimits
                )

                // Activate button - only if pending activation
                if viewModel.canActivate {
                    quickActionButton(
                        icon: "checkmark.circle",
                        title: "Activate Card",
                        subtitle: "Activate your new card",
                        style: .primary,
                        action: viewModel.activateCard
                    )
                }

                // Block button - only if active
                if viewModel.canBlock {
                    quickActionButton(
                        icon: "lock.shield",
                        title: "Block Card",
                        subtitle: "Temporarily block this card",
                        style: .destructive,
                        action: viewModel.blockCard
                    )
                }

                // Unblock button - if card is blocked
                if viewModel.isBlocked {
                    quickActionButton(
                        icon: "lock.open",
                        title: "Unblock Card",
                        subtitle: card.blockReason?.canUnblock == true
                            ? "Restore card functionality"
                            : "Contact support required",
                        style: .primary,
                        action: viewModel.unblockCard
                    )

                    // Show blocked reason info
                    blockedInfoView(card: card)
                }

                // Terminal state message - if card is expired or cancelled
                if viewModel.isTerminalState {
                    terminalStateInfoView(card: card)
                }
            }
        }
        .padding(.horizontal)
    }

    // MARK: - Recent Transactions Section

    private var recentTransactionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                sectionHeader("Recent Transactions")
                Spacer()
                if !viewModel.recentTransactions.isEmpty {
                    Button(action: viewModel.showTransactionHistory) {
                        Text("See All")
                            .font(.subheadline)
                            .foregroundColor(.blue)
                    }
                }
            }
            .padding(.horizontal)

            if viewModel.recentTransactions.isEmpty {
                emptyTransactionsView
                    .padding(.horizontal)
            } else {
                VStack(spacing: 0) {
                    ForEach(viewModel.recentTransactions) { transaction in
                        TransactionCell(transaction: transaction)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)

                        if transaction.id != viewModel.recentTransactions.last?.id {
                            Divider()
                                .padding(.leading, 68)
                        }
                    }
                }
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
                .padding(.horizontal)
            }
        }
    }

    // MARK: - Helper Views

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.headline)
            .fontWeight(.semibold)
            .foregroundColor(.primary)
    }

    private func detailRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
                .foregroundColor(.primary)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
    }

    private func formattedExpiry(month: Int, year: Int) -> String {
        let monthString = String(format: "%02d", month)
        let yearString = String(year % 100)
        return "\(monthString)/\(yearString)"
    }

    private enum QuickActionStyle {
        case standard
        case primary
        case destructive

        var backgroundColor: Color {
            switch self {
            case .standard:
                return Color(.systemBackground)
            case .primary:
                return Color.blue
            case .destructive:
                return Color.red
            }
        }

        var foregroundColor: Color {
            switch self {
            case .standard:
                return .primary
            case .primary, .destructive:
                return .white
            }
        }

        var iconColor: Color {
            switch self {
            case .standard:
                return .blue
            case .primary, .destructive:
                return .white
            }
        }

        var subtitleColor: Color {
            switch self {
            case .standard:
                return .secondary
            case .primary, .destructive:
                return .white.opacity(0.8)
            }
        }
    }

    private func quickActionButton(
        icon: String,
        title: String,
        subtitle: String,
        style: QuickActionStyle,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(style.iconColor)
                    .frame(width: 44, height: 44)
                    .background(style == .standard ? Color.blue.opacity(0.1) : Color.clear)
                    .cornerRadius(10)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(style.foregroundColor)

                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(style.subtitleColor)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(style == .standard ? .secondary : style.foregroundColor.opacity(0.7))
            }
            .padding(16)
            .background(style.backgroundColor)
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
        }
        .buttonStyle(.plain)
    }

    private func blockedInfoView(card: Card) -> some View {
        HStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.title2)
                .foregroundColor(.orange)
                .frame(width: 44, height: 44)
                .background(Color.orange.opacity(0.1))
                .cornerRadius(10)

            VStack(alignment: .leading, spacing: 2) {
                Text("Card Blocked")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)

                if let reason = card.blockReason {
                    Text("Reason: \(reason.displayName)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Text("Contact support to unblock")
                    .font(.caption)
                    .foregroundColor(.orange)
            }

            Spacer()
        }
        .padding(16)
        .background(Color.orange.opacity(0.05))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.orange.opacity(0.3), lineWidth: 1)
        )
    }

    private func terminalStateInfoView(card: Card) -> some View {
        HStack(spacing: 16) {
            Image(systemName: card.status == .expired ? "clock.badge.exclamationmark" : "xmark.circle.fill")
                .font(.title2)
                .foregroundColor(.gray)
                .frame(width: 44, height: 44)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)

            VStack(alignment: .leading, spacing: 2) {
                Text(card.status == .expired ? "Card Expired" : "Card Cancelled")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)

                Text(card.status == .expired
                     ? "This card has expired. Please request a new card."
                     : "This card has been cancelled and cannot be used.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding(16)
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
        )
    }

    private var emptyTransactionsView: some View {
        HStack {
            Spacer()
            VStack(spacing: 12) {
                Image(systemName: "creditcard.and.123")
                    .font(.system(size: 40))
                    .foregroundColor(.secondary.opacity(0.5))

                Text("No recent transactions")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 32)
            Spacer()
        }
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

// MARK: - Preview

#if DEBUG
struct CardDetailView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            CardDetailView(viewModel: createPreviewViewModel())
        }
        .navigationViewStyle(.stack)
    }

    static func createPreviewViewModel() -> CardDetailViewModel {
        // This is just for preview - actual dependencies would be injected
        let container = DependencyContainer()
        let viewModel = CardDetailViewModel(
            cardId: "CARD001",
            cardService: container.cardService,
            accountService: container.accountService,
            transactionService: container.transactionService,
            coordinator: nil
        )
        return viewModel
    }
}
#endif
