//
//  AddBeneficiaryView.swift
//  BankingApp
//
//  Add/Edit beneficiary form with validation and account verification.
//

import SwiftUI

struct AddBeneficiaryView: View {
    @ObservedObject var viewModel: AddBeneficiaryViewModel
    @State private var hasInteractedWithName = false
    @State private var hasInteractedWithAccount = false
    @State private var hasInteractedWithIban = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Beneficiary Type Picker
                typePickerSection

                // Name Field
                nameSection

                // Account Number Field
                accountNumberSection

                // IBAN Field (International only)
                if viewModel.showIbanField {
                    ibanSection
                }

                // Validate Button
                validateSection

                // Bank Name Display (after validation)
                if let result = viewModel.validationResult, result.isValid {
                    bankNameSection(bankName: result.bankName ?? "Verified")
                }

                // Favorite Toggle
                favoriteSection

                Spacer(minLength: 20)

                // Save Button
                saveSection
            }
            .padding()
        }
        .navigationTitle(viewModel.navigationTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    viewModel.cancel()
                }
            }
        }
        .onAppear {
            viewModel.loadExistingData()
        }
    }

    // MARK: - Sections

    private var typePickerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Beneficiary Type")
                .font(.caption)
                .foregroundColor(.secondary)

            Picker("Type", selection: $viewModel.beneficiaryType) {
                Text("Internal").tag(BeneficiaryType.internal)
                Text("External").tag(BeneficiaryType.external)
                Text("International").tag(BeneficiaryType.international)
            }
            .pickerStyle(.segmented)
            .onChange(of: viewModel.beneficiaryType) { _ in
                viewModel.onBeneficiaryTypeChanged()
            }
        }
    }

    private var nameSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Beneficiary Name")
                .font(.caption)
                .foregroundColor(.secondary)

            HStack {
                TextField("Enter name", text: $viewModel.name)
                    .textFieldStyle(.roundedBorder)
                    .autocapitalization(.words)
                    .disableAutocorrection(true)
                    .onChange(of: viewModel.name) { _ in
                        hasInteractedWithName = true
                    }

                if viewModel.isNameValid && hasInteractedWithName {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                }
            }

            if !viewModel.isNameValid && hasInteractedWithName {
                Text("Name is required")
                    .font(.caption)
                    .foregroundColor(.red)
            }
        }
    }

    private var accountNumberSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Account Number")
                .font(.caption)
                .foregroundColor(.secondary)

            HStack {
                TextField("Enter account number", text: $viewModel.accountNumber)
                    .textFieldStyle(.roundedBorder)
                    .keyboardType(.numberPad)
                    .onChange(of: viewModel.accountNumber) { _ in
                        hasInteractedWithAccount = true
                        viewModel.onAccountNumberChanged()
                    }

                if viewModel.isAccountNumberValid && hasInteractedWithAccount {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                }
            }

            if !viewModel.isAccountNumberValid && hasInteractedWithAccount {
                Text("Enter a valid account number (minimum 8 digits)")
                    .font(.caption)
                    .foregroundColor(.red)
            }
        }
    }

    private var ibanSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("IBAN")
                .font(.caption)
                .foregroundColor(.secondary)

            HStack {
                TextField("Enter IBAN", text: $viewModel.iban)
                    .textFieldStyle(.roundedBorder)
                    .textInputAutocapitalization(.characters)
                    .disableAutocorrection(true)
                    .onChange(of: viewModel.iban) { _ in
                        hasInteractedWithIban = true
                    }

                if viewModel.isIbanValid && hasInteractedWithIban && !viewModel.iban.isEmpty {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                }
            }

            if !viewModel.isIbanValid && hasInteractedWithIban {
                Text("Enter a valid IBAN (15-34 characters)")
                    .font(.caption)
                    .foregroundColor(.red)
            }
        }
    }

    private var validateSection: some View {
        VStack(spacing: 8) {
            Button(action: {
                Task { await viewModel.validateBeneficiary() }
            }) {
                HStack(spacing: 8) {
                    if viewModel.isValidating {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    }
                    Text("Validate Account")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(viewModel.canValidate && !viewModel.isValidating ? Color.blue : Color.gray)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .disabled(!viewModel.canValidate || viewModel.isValidating)

            if let error = viewModel.error, viewModel.validationResult?.isValid != true {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
            }
        }
    }

    private func bankNameSection(bankName: String) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Bank Name")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(bankName)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }

            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
                .font(.title2)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }

    private var favoriteSection: some View {
        Toggle("Mark as Favorite", isOn: $viewModel.isFavorite)
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(10)
    }

    private var saveSection: some View {
        VStack(spacing: 8) {
            Button(action: {
                Task { await viewModel.saveBeneficiary() }
            }) {
                HStack(spacing: 8) {
                    if viewModel.isSaving {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    }
                    Text("Save Beneficiary")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(viewModel.canSave && !viewModel.isSaving ? Color.blue : Color.gray)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .disabled(!viewModel.canSave || viewModel.isSaving)

            if let error = viewModel.error, viewModel.validationResult?.isValid == true {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
            }
        }
    }
}
