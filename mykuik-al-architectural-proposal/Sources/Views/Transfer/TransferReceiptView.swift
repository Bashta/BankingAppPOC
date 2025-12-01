//
//  TransferReceiptView.swift
//  BankingApp
//
//  Transfer receipt view showing completion details after successful transfer.
//  Story 4.5: Implement Transfer Receipt View
//

import SwiftUI

struct TransferReceiptView: View {
    @ObservedObject var viewModel: TransferReceiptViewModel

    var body: some View {
        Group {
            if let transfer = viewModel.transfer {
                content(transfer: transfer)
            } else if viewModel.error != nil {
                ErrorView(
                    message: "Unable to load transfer details",
                    retryAction: { Task { await viewModel.loadData() } }
                )
            } else {
                // Initial state or loading state
                LoadingView(message: "Loading receipt...")
            }
        }
        .navigationTitle("Receipt")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .task {
            await viewModel.loadData()
        }
        .overlay(alignment: .top) {
            if viewModel.showCopiedToast {
                copiedToast
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.3), value: viewModel.showCopiedToast)
    }

    // MARK: - Content

    private func content(transfer: Transfer) -> some View {
        ScrollView {
            VStack(spacing: 24) {
                // Success Header
                successHeader

                // Transfer Details Card
                transferDetailsCard(transfer: transfer)

                // Action Buttons
                actionButtons
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
    }

    // MARK: - Success Header

    private var successHeader: some View {
        VStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 64))
                .foregroundColor(.green)

            Text("Transfer Successful")
                .font(.title2)
                .fontWeight(.bold)
        }
        .padding(.top, 24)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Transfer Successful")
    }

    // MARK: - Transfer Details Card

    private func transferDetailsCard(transfer: Transfer) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            // Reference Number (prominent, copyable)
            referenceSection(transfer: transfer)

            Divider()

            // From / To
            detailRow(label: "From", value: transfer.sourceAccountName ?? "Account")
            detailRow(label: "To", value: transfer.destinationName)

            Divider()

            // Amount (large, prominent)
            amountSection(transfer: transfer)

            Divider()

            // Description
            if !transfer.description.isEmpty {
                detailRow(label: "Description", value: transfer.description)
            } else {
                detailRow(label: "Description", value: "No description")
            }

            // Date and Time
            detailRow(label: "Date", value: transfer.date.fullDateTimeString())

            // Status
            statusRow(transfer: transfer)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }

    private func referenceSection(transfer: Transfer) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Reference")
                .font(.caption)
                .foregroundColor(.secondary)

            HStack {
                Text(transfer.reference)
                    .font(.headline)
                    .fontWeight(.bold)

                Spacer()

                Button(action: viewModel.copyReference) {
                    HStack(spacing: 4) {
                        Image(systemName: "doc.on.doc")
                        Text("Copy")
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                }
                .accessibilityLabel("Copy reference number")
            }
        }
    }

    private func amountSection(transfer: Transfer) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Amount")
                .font(.caption)
                .foregroundColor(.secondary)
            Text(transfer.amount.formatted(currency: transfer.currency))
                .font(.title)
                .fontWeight(.bold)
        }
    }

    private func detailRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline)
                .multilineTextAlignment(.trailing)
        }
    }

    private func statusRow(transfer: Transfer) -> some View {
        HStack {
            Text("Status")
                .font(.caption)
                .foregroundColor(.secondary)
            Spacer()
            TransferStatusBadge(status: transfer.status)
        }
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        VStack(spacing: 12) {
            // Share Receipt Button (secondary style)
            Button(action: viewModel.downloadReceipt) {
                HStack {
                    Image(systemName: "square.and.arrow.up")
                    Text("Share Receipt")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(.systemGray6))
                .foregroundColor(.blue)
                .cornerRadius(12)
            }
            .accessibilityLabel("Share receipt")

            // Done Button (primary style)
            Button(action: viewModel.navigateToHome) {
                Text("Done")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .accessibilityLabel("Done, return to home")
        }
        .padding(.top, 16)
    }

    // MARK: - Toast

    private var copiedToast: some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
            Text("Reference copied")
                .font(.subheadline)
                .fontWeight(.medium)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
        .cornerRadius(8)
        .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
        .padding(.top, 60)
    }
}

// MARK: - Preview

#Preview("Transfer Receipt - Completed") {
    NavigationView {
        TransferReceiptView(
            viewModel: {
                let vm = TransferReceiptViewModel(
                    transferId: "TRF001",
                    transferService: MockTransferService(),
                    coordinator: nil
                )
                // Manually set transfer for preview
                vm.transfer = Transfer(
                    id: "TRF001",
                    sourceAccountId: "ACC001",
                    destinationType: .beneficiary(beneficiaryId: "BEN001"),
                    amount: 250.00,
                    currency: "ALL",
                    description: "Monthly rent payment",
                    reference: "REF00000001",
                    status: .completed,
                    date: Date(),
                    type: .external,
                    initiatedDate: Date().addingTimeInterval(-300),
                    completedDate: Date(),
                    otpRequired: false,
                    otpReference: nil,
                    destinationName: "John Smith",
                    sourceAccountName: "Primary Checking"
                )
                return vm
            }()
        )
    }
}

#Preview("Transfer Receipt - Loading") {
    NavigationView {
        TransferReceiptView(
            viewModel: {
                let vm = TransferReceiptViewModel(
                    transferId: "TRF001",
                    transferService: MockTransferService(),
                    coordinator: nil
                )
                vm.isLoading = true
                return vm
            }()
        )
    }
}
