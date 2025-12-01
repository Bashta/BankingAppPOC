//
//  CardLimitsView.swift
//  BankingApp
//
//  View for managing card spending limits with sliders,
//  text input, validation, and save/cancel actions.
//  Story 5.5: Implement Card Spending Limits Management
//

import SwiftUI

struct CardLimitsView: View {
    @ObservedObject var viewModel: CardLimitsViewModel

    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.limits == nil {
                LoadingView(message: "Loading limits...")
            } else if viewModel.isSuccess {
                successSection
            } else if viewModel.limits != nil {
                contentView
            } else if viewModel.error != nil {
                errorStateView
            } else {
                LoadingView(message: "Loading limits...")
            }
        }
        .navigationTitle("Spending Limits")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.loadData()
        }
    }

    // MARK: - Content View

    private var contentView: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Card Header
                cardHeaderSection

                // Current Limits Display
                currentLimitsSection

                // Editable Limits Section
                editableLimitsSection

                // Error Banner
                if let error = viewModel.error {
                    errorBanner(error: error)
                }

                // Action Buttons
                actionButtonsSection
            }
            .padding(20)
        }
    }

    // MARK: - Card Header Section

    private var cardHeaderSection: some View {
        HStack(spacing: 12) {
            Image(systemName: "creditcard.fill")
                .font(.title2)
                .foregroundColor(.blue)

            Text("Card ****\(viewModel.cardId.suffix(4))")
                .font(.headline)
                .foregroundColor(.primary)

            Spacer()
        }
        .padding(16)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }

    // MARK: - Current Limits Section

    private var currentLimitsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Current Limits")
                .font(.headline)
                .foregroundColor(.primary)

            VStack(spacing: 0) {
                ForEach(LimitField.allCases, id: \.self) { field in
                    currentLimitRow(for: field)
                    if field != LimitField.allCases.last {
                        Divider()
                            .padding(.leading, 52)
                    }
                }
            }
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
    }

    private func currentLimitRow(for field: LimitField) -> some View {
        HStack(spacing: 12) {
            Image(systemName: field.iconName)
                .font(.title3)
                .foregroundColor(.secondary)
                .frame(width: 32)

            Text(field.displayName)
                .font(.body)
                .foregroundColor(.primary)

            Spacer()

            if let original = viewModel.originalValue(for: field) {
                Text(formatCurrency(original))
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    // MARK: - Editable Limits Section

    private var editableLimitsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Update Limits")
                .font(.headline)
                .foregroundColor(.primary)

            VStack(spacing: 20) {
                ForEach(LimitField.allCases, id: \.self) { field in
                    LimitEditRow(
                        field: field,
                        value: binding(for: field),
                        originalValue: viewModel.originalValue(for: field),
                        validationError: viewModel.validationError(for: field),
                        isDisabled: viewModel.isSaving,
                        onValidate: { viewModel.validateField(field) },
                        onClearError: { viewModel.clearFieldError(field) }
                    )
                }
            }
        }
    }

    private func binding(for field: LimitField) -> Binding<Decimal> {
        Binding(
            get: { viewModel.value(for: field) },
            set: { newValue in
                viewModel.updateValue(for: field, value: newValue)
            }
        )
    }

    // MARK: - Error Banner

    private func errorBanner(error: Error) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.circle.fill")
                .foregroundColor(.red)
            Text(error.localizedDescription)
                .font(.subheadline)
                .foregroundColor(.red)
            Spacer()
        }
        .padding(16)
        .background(Color.red.opacity(0.1))
        .cornerRadius(12)
    }

    // MARK: - Action Buttons Section

    private var actionButtonsSection: some View {
        VStack(spacing: 12) {
            ActionButton(
                title: "Save Changes",
                isLoading: viewModel.isSaving,
                isDisabled: !viewModel.isAllValid || !viewModel.hasChanges
            ) {
                Task {
                    await viewModel.saveLimits()
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
            .disabled(viewModel.isSaving)
        }
    }

    // MARK: - Success Section

    private var successSection: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.green)

            Text("Limits Updated Successfully")
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

    // MARK: - Error State View

    private var errorStateView: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 60))
                .foregroundColor(.orange)

            Text("Unable to Load Limits")
                .font(.title2)
                .fontWeight(.bold)

            if let error = viewModel.error {
                Text(error.localizedDescription)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }

            ActionButton(
                title: "Try Again",
                isLoading: viewModel.isLoading
            ) {
                Task {
                    await viewModel.loadData()
                }
            }
            .padding(.horizontal, 40)

            Spacer()
        }
        .padding(20)
    }

    // MARK: - Helpers

    private func formatCurrency(_ value: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: value as NSDecimalNumber) ?? "$\(value)"
    }
}

// MARK: - LimitEditRow Component

struct LimitEditRow: View {
    let field: LimitField
    @Binding var value: Decimal
    let originalValue: Decimal?
    let validationError: String?
    let isDisabled: Bool
    let onValidate: () -> Void
    let onClearError: () -> Void

    @State private var textValue: String = ""
    @FocusState private var isTextFieldFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header with icon and label
            HStack(spacing: 8) {
                Image(systemName: field.iconName)
                    .font(.title3)
                    .foregroundColor(.blue)
                    .frame(width: 28)

                Text(field.displayName)
                    .font(.headline)

                Spacer()

                // Show change indicator if modified
                if let original = originalValue, value != original {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.right")
                            .font(.caption)
                        Text(formatCurrency(value))
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(.blue)
                }
            }

            // Slider
            HStack(spacing: 12) {
                Text("$0")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(width: 24)

                Slider(
                    value: sliderBinding,
                    in: 0...Double(truncating: field.maxValue as NSDecimalNumber),
                    step: 1
                )
                .disabled(isDisabled)
                .onChange(of: value) { _ in
                    onClearError()
                }

                Text("$\(Int(truncating: field.maxValue as NSDecimalNumber))")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(width: 48)
            }

            // Text Input
            HStack {
                Text("$")
                    .font(.body)
                    .foregroundColor(.secondary)

                TextField("0", text: $textValue)
                    .keyboardType(.numberPad)
                    .font(.body)
                    .focused($isTextFieldFocused)
                    .disabled(isDisabled)
                    .onChange(of: textValue) { newValue in
                        // Filter to only digits
                        let filtered = newValue.filter { $0.isNumber }
                        if filtered != newValue {
                            textValue = filtered
                        }
                        // Update the decimal value
                        if let intValue = Int(filtered) {
                            value = Decimal(intValue)
                            onClearError()
                        }
                    }
                    .onChange(of: value) { newValue in
                        // Sync text value when slider changes
                        if !isTextFieldFocused {
                            textValue = "\(Int(truncating: newValue as NSDecimalNumber))"
                        }
                    }
                    .onChange(of: isTextFieldFocused) { focused in
                        if !focused {
                            // Validate on blur
                            onValidate()
                        }
                    }
                    .onAppear {
                        textValue = "\(Int(truncating: value as NSDecimalNumber))"
                    }

                Spacer()

                Text("Max: $\(Int(truncating: field.maxValue as NSDecimalNumber))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Color(.systemGray6))
            .cornerRadius(8)

            // Validation Error
            if let error = validationError {
                HStack(spacing: 4) {
                    Image(systemName: "exclamationmark.circle.fill")
                        .font(.caption)
                    Text(error)
                        .font(.caption)
                }
                .foregroundColor(.red)
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }

    private var sliderBinding: Binding<Double> {
        Binding(
            get: { Double(truncating: value as NSDecimalNumber) },
            set: { newValue in
                // Snap to whole number
                let snapped = Decimal(Int(newValue.rounded()))
                value = snapped
            }
        )
    }

    private func formatCurrency(_ value: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: value as NSDecimalNumber) ?? "$\(value)"
    }
}

// MARK: - Preview

#if DEBUG
struct CardLimitsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            CardLimitsView(viewModel: createPreviewViewModel())
        }
        .navigationViewStyle(.stack)
    }

    static func createPreviewViewModel() -> CardLimitsViewModel {
        // This is just for preview - actual dependencies would be injected
        let container = DependencyContainer()
        let viewModel = CardLimitsViewModel(
            cardId: "CARD001",
            cardService: container.cardService,
            coordinator: CardsCoordinator(
                parent: AppCoordinator(dependencyContainer: container),
                dependencyContainer: container
            )
        )
        return viewModel
    }
}
#endif
