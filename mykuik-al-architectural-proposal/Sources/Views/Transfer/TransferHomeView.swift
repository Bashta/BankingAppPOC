//
//  TransferHomeView.swift
//  BankingApp
//
//  Transfer home screen with action cards for transfer types and recent transfers list.
//  Story 4.1: Implement Transfer Home Screen
//

import SwiftUI

struct TransferHomeView: View {
    @ObservedObject var viewModel: TransferHomeViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Action Cards
                actionCardsSection

                // Manage Beneficiaries Link
                manageBeneficiariesButton

                // Recent Transfers
                recentTransfersSection
            }
            .padding()
        }
        .navigationTitle("Transfer")
        .navigationBarTitleDisplayMode(.large)
        .task {
            await viewModel.loadData()
        }
        .refreshable {
            await viewModel.refresh()
        }
    }

    // MARK: - Action Cards Section

    private var actionCardsSection: some View {
        VStack(spacing: 16) {
            // Internal Transfer Card
            Button(action: viewModel.startInternalTransfer) {
                actionCard(
                    icon: "arrow.left.arrow.right",
                    title: "Transfer Between Accounts",
                    subtitle: "Move money between your accounts"
                )
            }
            .buttonStyle(.plain)

            // External Transfer Card
            Button(action: viewModel.startExternalTransfer) {
                actionCard(
                    icon: "person.crop.circle.badge.checkmark",
                    title: "Transfer to Beneficiary",
                    subtitle: "Send money to saved recipients"
                )
            }
            .buttonStyle(.plain)
        }
    }

    private func actionCard(icon: String, title: String, subtitle: String) -> some View {
        HStack {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 44, height: 44)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(10)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }

    // MARK: - Manage Beneficiaries Button

    private var manageBeneficiariesButton: some View {
        Button(action: viewModel.showBeneficiaries) {
            HStack {
                Image(systemName: "person.2")
                Text("Manage Beneficiaries")
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
            }
            .foregroundColor(.blue)
        }
        .padding(.horizontal)
    }

    // MARK: - Recent Transfers Section

    @ViewBuilder
    private var recentTransfersSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Transfers")
                .font(.headline)
                .padding(.horizontal, 4)

            if viewModel.isLoading && viewModel.recentTransfers.isEmpty {
                LoadingView(message: "Loading transfers...")
                    .frame(minHeight: 100)
            } else if let error = viewModel.error, viewModel.recentTransfers.isEmpty {
                ErrorView(
                    message: "Unable to load transfers",
                    retryAction: { Task { await viewModel.loadData() } }
                )
            } else if viewModel.recentTransfers.isEmpty {
                EmptyStateView(
                    iconName: "arrow.left.arrow.right.circle",
                    title: "No Recent Transfers",
                    message: "Your recent transfers will appear here"
                )
                .frame(minHeight: 150)
            } else {
                transfersList
            }
        }
    }

    private var transfersList: some View {
        VStack(spacing: 0) {
            ForEach(viewModel.recentTransfers) { transfer in
                Button(action: { viewModel.showTransferDetail(transfer) }) {
                    TransferCell(transfer: transfer)
                }
                .buttonStyle(.plain)

                if transfer.id != viewModel.recentTransfers.last?.id {
                    Divider()
                        .padding(.leading, 64)
                }
            }
        }
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}
