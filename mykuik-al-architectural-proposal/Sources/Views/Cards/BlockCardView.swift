//
//  BlockCardView.swift
//  BankingApp
//
//  View for blocking/unblocking cards with reason selection,
//  confirmation alerts, and success/error states.
//  Story 5.4: Implement Block/Unblock Card Flow
//

import SwiftUI

struct BlockCardView: View {
    @ObservedObject var viewModel: BlockCardViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                if viewModel.isSuccess {
                    successSection
                } else if viewModel.isBlockMode {
                    blockModeContent
                } else {
                    unblockModeContent
                }
            }
            .padding(24)
        }
        .navigationTitle(viewModel.isBlockMode ? "Block Card" : "Unblock Card")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Block Card?", isPresented: $viewModel.showBlockConfirmation) {
            Button("Cancel", role: .cancel) {
                viewModel.dismissBlockAlert()
            }
            Button("Block", role: .destructive) {
                Task {
                    await viewModel.confirmBlock()
                }
            }
        } message: {
            Text("Are you sure you want to block this card? All transactions will be prevented.")
        }
        .alert("Unblock Card?", isPresented: $viewModel.showUnblockConfirmation) {
            Button("Cancel", role: .cancel) {
                viewModel.dismissUnblockAlert()
            }
            Button("Unblock") {
                Task {
                    await viewModel.confirmUnblock()
                }
            }
        } message: {
            Text("Are you sure you want to unblock this card? Transactions will be enabled again.")
        }
    }

    // MARK: - Block Mode Content

    private var blockModeContent: some View {
        VStack(spacing: 24) {
            // Warning Banner
            warningBanner

            // Reason Selection
            reasonSelectionSection

            // Additional Notes
            additionalNotesSection

            // Error Message
            if let error = viewModel.error {
                errorSection(error: error)
            }

            Spacer(minLength: 20)

            // Action Buttons
            blockActionButtons
        }
    }

    // MARK: - Unblock Mode Content

    private var unblockModeContent: some View {
        VStack(spacing: 24) {
            // Info Banner
            infoBanner

            if viewModel.canUnblock {
                // Can unblock
                unblockableSection
            } else {
                // Cannot unblock
                cannotUnblockSection
            }

            // Error Message
            if let error = viewModel.error {
                errorSection(error: error)
            }

            Spacer(minLength: 20)
        }
    }

    // MARK: - Warning Banner (Block Mode)

    private var warningBanner: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.title2)
                .foregroundColor(.white)

            Text(viewModel.warningMessage)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.white)

            Spacer()
        }
        .padding(16)
        .background(Color.red)
        .cornerRadius(12)
    }

    // MARK: - Info Banner (Unblock Mode)

    private var infoBanner: some View {
        HStack(spacing: 12) {
            Image(systemName: "info.circle.fill")
                .font(.title2)
                .foregroundColor(.white)

            Text(viewModel.warningMessage)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.white)

            Spacer()
        }
        .padding(16)
        .background(Color.orange)
        .cornerRadius(12)
    }

    // MARK: - Reason Selection Section

    private var reasonSelectionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Select a reason")
                .font(.headline)
                .padding(.horizontal, 4)

            VStack(spacing: 0) {
                ForEach(BlockReason.allCases, id: \.self) { reason in
                    reasonRow(for: reason)

                    if reason != BlockReason.allCases.last {
                        Divider()
                            .padding(.leading, 52)
                    }
                }
            }
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
    }

    private func reasonRow(for reason: BlockReason) -> some View {
        Button {
            viewModel.selectReason(reason)
        } label: {
            HStack(spacing: 12) {
                Image(systemName: reason.iconName)
                    .font(.title3)
                    .foregroundColor(reasonColor(for: reason))
                    .frame(width: 32)

                VStack(alignment: .leading, spacing: 2) {
                    Text(reason.shortName)
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)

                    Text(reason.reasonDescription)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                if viewModel.selectedReason == reason {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.blue)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(viewModel.isLoading)
    }

    private func reasonColor(for reason: BlockReason) -> Color {
        switch reason {
        case .lost:
            return .orange
        case .stolen:
            return .red
        case .damaged:
            return .yellow
        case .suspicious:
            return .purple
        }
    }

    // MARK: - Additional Notes Section

    private var additionalNotesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Additional details (optional)")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding(.horizontal, 4)

            // iOS 15 compatible multiline text input
            TextEditor(text: Binding(
                get: { viewModel.additionalNotes },
                set: { viewModel.updateNotes($0) }
            ))
            .frame(minHeight: 80, maxHeight: 120)
            .padding(8)
            .background(Color(.systemGray6))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color(.systemGray4), lineWidth: 1)
            )
            .disabled(viewModel.isLoading)
            .overlay(
                Group {
                    if viewModel.additionalNotes.isEmpty {
                        Text("Add any additional details...")
                            .foregroundColor(Color(.placeholderText))
                            .padding(.leading, 12)
                            .padding(.top, 16)
                    }
                },
                alignment: .topLeading
            )
        }
    }

    // MARK: - Unblockable Section

    private var unblockableSection: some View {
        VStack(spacing: 20) {
            Image(systemName: "lock.open.fill")
                .font(.system(size: 50))
                .foregroundColor(.blue)

            Text("You can unblock your card since it was blocked for suspicious activity")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            ActionButton(
                title: "Unblock Card",
                isLoading: viewModel.isUnblocking,
                isDisabled: false
            ) {
                viewModel.showUnblockAlert()
            }

            Button(action: {
                viewModel.cancel()
            }) {
                Text("Cancel")
                    .font(.headline)
                    .foregroundColor(.secondary)
                    .frame(height: 50)
                    .frame(maxWidth: .infinity)
            }
            .disabled(viewModel.isLoading)
        }
    }

    // MARK: - Cannot Unblock Section

    private var cannotUnblockSection: some View {
        VStack(spacing: 20) {
            Image(systemName: "lock.fill")
                .font(.system(size: 50))
                .foregroundColor(.red)

            Text(cannotUnblockMessage)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            ActionButton(
                title: "Contact Support",
                isLoading: false,
                isDisabled: false
            ) {
                viewModel.contactSupport()
            }

            Button(action: {
                viewModel.cancel()
            }) {
                Text("Go Back")
                    .font(.headline)
                    .foregroundColor(.secondary)
                    .frame(height: 50)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    private var cannotUnblockMessage: String {
        if let reason = viewModel.blockReason {
            return "This card cannot be unblocked because it was reported as \(reason.shortName.lowercased()). Please contact support for a replacement card."
        }
        return "This card cannot be unblocked. Please contact support for assistance."
    }

    // MARK: - Error Section

    private func errorSection(error: Error) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.circle.fill")
                .foregroundColor(.red)
            Text(errorMessage(for: error))
                .font(.subheadline)
                .foregroundColor(.red)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.red.opacity(0.1))
        .cornerRadius(8)
    }

    /// Converts error to user-friendly message
    private func errorMessage(for error: Error) -> String {
        if let cardError = error as? CardError {
            switch cardError {
            case .cardNotFound:
                return "Card not found. Please try again."
            case .cardAlreadyBlocked:
                return "This card is already blocked."
            case .cardNotBlocked:
                return "This card is not blocked."
            case .cannotUnblock:
                return "This card cannot be unblocked. Please contact support."
            default:
                return "Operation failed. Please try again."
            }
        }
        return error.localizedDescription
    }

    // MARK: - Success Section

    private var successSection: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.green)

            Text(viewModel.isBlockMode ? "Card Blocked Successfully" : "Card Unblocked Successfully")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.green)

            Text("Redirecting to card details...")
                .font(.subheadline)
                .foregroundColor(.secondary)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.vertical, 60)
    }

    // MARK: - Block Action Buttons

    private var blockActionButtons: some View {
        VStack(spacing: 12) {
            ActionButton(
                title: "Block Card",
                isLoading: viewModel.isBlocking,
                isDisabled: !viewModel.isValidInput
            ) {
                viewModel.showBlockAlert()
            }

            Button(action: {
                viewModel.cancel()
            }) {
                Text("Cancel")
                    .font(.headline)
                    .foregroundColor(.secondary)
                    .frame(height: 50)
                    .frame(maxWidth: .infinity)
            }
            .disabled(viewModel.isLoading)
        }
    }
}

// MARK: - BlockReason CaseIterable

extension BlockReason: CaseIterable {
    static var allCases: [BlockReason] {
        [.lost, .stolen, .damaged, .suspicious]
    }
}
