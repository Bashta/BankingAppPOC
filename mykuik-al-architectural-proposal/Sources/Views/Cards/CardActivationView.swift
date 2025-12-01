//
//  CardActivationView.swift
//  BankingApp
//
//  View for card activation with 4-digit verification input,
//  action buttons, success/error states.
//  Story 5.3: Implement Card Activation Flow
//

import SwiftUI

struct CardActivationView: View {
    @ObservedObject var viewModel: CardActivationViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                // Icon and Instructions
                instructionSection

                // Input Field
                inputSection

                // Error Message
                if let error = viewModel.error {
                    errorSection(error: error)
                }

                // Success State
                if viewModel.isSuccess {
                    successSection
                }

                Spacer(minLength: 20)

                // Action Buttons
                if !viewModel.isSuccess {
                    actionButtons
                }
            }
            .padding(24)
        }
        .navigationTitle("Activate Card")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Instruction Section

    private var instructionSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "creditcard.fill")
                .font(.system(size: 60))
                .foregroundColor(.blue)

            Text("Activate Your Card")
                .font(.title2)
                .fontWeight(.bold)

            Text("Enter the last 4 digits of your card number to activate")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 20)
    }

    // MARK: - Input Section

    private var inputSection: some View {
        VStack(spacing: 8) {
            TextField("0000", text: Binding(
                get: { viewModel.lastFourDigits },
                set: { viewModel.updateLastFourDigits($0) }
            ))
            .keyboardType(.numberPad)
            .multilineTextAlignment(.center)
            .font(.system(size: 40, weight: .bold, design: .monospaced))
            .frame(maxWidth: 200)
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        viewModel.error != nil ? Color.red :
                            (viewModel.isValidInput ? Color.green : Color.clear),
                        lineWidth: 2
                    )
            )

            // Helper text
            Text("Last 4 digits")
                .font(.caption)
                .foregroundColor(.secondary)
        }
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
            case .invalidLastFourDigits:
                return "Invalid card number. Please check the last 4 digits."
            case .cardAlreadyActive:
                return "This card is already active."
            case .cardNotFound:
                return "Card not found. Please try again."
            default:
                return "Activation failed. Please try again."
            }
        }
        return error.localizedDescription
    }

    // MARK: - Success Section

    private var successSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.green)

            Text("Card Activated Successfully")
                .font(.headline)
                .foregroundColor(.green)

            Text("Redirecting to card details...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 20)
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        VStack(spacing: 12) {
            ActionButton(
                title: "Activate Card",
                isLoading: viewModel.isActivating,
                isDisabled: !viewModel.isValidInput
            ) {
                Task {
                    await viewModel.activateCard()
                }
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
        }
    }
}

// MARK: - Preview

#if DEBUG
struct CardActivationView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            CardActivationView(viewModel: createPreviewViewModel())
        }
        .navigationViewStyle(.stack)
    }

    static func createPreviewViewModel() -> CardActivationViewModel {
        let container = DependencyContainer()
        return CardActivationViewModel(
            cardId: "CARD003",
            cardService: container.cardService,
            coordinator: createMockCoordinator()
        )
    }

    static func createMockCoordinator() -> CardsCoordinator {
        // This is for preview only - actual coordinator would be provided by app
        fatalError("Coordinator should be provided by the app")
    }
}
#endif
