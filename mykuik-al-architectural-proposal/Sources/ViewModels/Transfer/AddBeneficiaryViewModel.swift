//
//  AddBeneficiaryViewModel.swift
//  BankingApp
//
//  ViewModel for add/edit beneficiary screen with form validation and service integration.
//

import Foundation
import Combine
import OSLog

final class AddBeneficiaryViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published var name: String = ""
    @Published var accountNumber: String = ""
    @Published var iban: String = ""
    @Published var beneficiaryType: BeneficiaryType = .external
    @Published var isFavorite: Bool = false
    @Published var isValidating = false
    @Published var isSaving = false
    @Published var validationResult: BeneficiaryValidation?
    @Published var error: String?

    // MARK: - Properties

    let existingBeneficiary: Beneficiary?

    // MARK: - Computed Properties

    var isEditMode: Bool {
        existingBeneficiary != nil
    }

    var navigationTitle: String {
        isEditMode ? "Edit Beneficiary" : "Add Beneficiary"
    }

    var isNameValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var isAccountNumberValid: Bool {
        // Basic validation: at least 8 digits
        let digits = accountNumber.filter { $0.isNumber }
        return digits.count >= 8
    }

    var isIbanValid: Bool {
        // For international type, require IBAN
        if beneficiaryType == .international {
            let cleanIban = iban.replacingOccurrences(of: " ", with: "")
            return cleanIban.count >= 15 && cleanIban.count <= 34
        }
        return true // Not required for other types
    }

    var canValidate: Bool {
        isAccountNumberValid
    }

    var canSave: Bool {
        isNameValid && validationResult?.isValid == true && isIbanValid
    }

    var showIbanField: Bool {
        beneficiaryType == .international
    }

    // MARK: - Dependencies

    private let beneficiaryService: BeneficiaryServiceProtocol
    weak var coordinator: TransferCoordinator?

    private var originalAccountNumber: String = ""

    // MARK: - Initialization

    init(
        beneficiaryService: BeneficiaryServiceProtocol,
        coordinator: TransferCoordinator?,
        existingBeneficiary: Beneficiary? = nil
    ) {
        self.beneficiaryService = beneficiaryService
        self.coordinator = coordinator
        self.existingBeneficiary = existingBeneficiary
    }

    // MARK: - Public Methods

    func loadExistingData() {
        guard let existing = existingBeneficiary else { return }

        name = existing.name
        accountNumber = existing.accountNumber
        originalAccountNumber = existing.accountNumber
        iban = existing.iban ?? ""
        beneficiaryType = existing.type
        isFavorite = existing.isFavorite

        // Pre-validate if editing (account already validated)
        validationResult = BeneficiaryValidation(
            isValid: true,
            bankName: existing.bankName,
            accountHolderName: nil,
            errorMessage: nil
        )

        Logger.transfer.debug("Loaded existing beneficiary for editing: \(existing.name)")
    }

    @MainActor
    func validateBeneficiary() async {
        guard canValidate else { return }

        isValidating = true
        error = nil
        defer { isValidating = false }

        do {
            let request = ValidateBeneficiaryRequest(
                accountNumber: accountNumber,
                type: beneficiaryType
            )

            validationResult = try await beneficiaryService.validateBeneficiary(request)

            if let result = validationResult, !result.isValid {
                error = result.errorMessage ?? "Account validation failed"
            }

            Logger.transfer.debug("Validated account: \(self.validationResult?.isValid == true ? "success" : "failed")")
        } catch {
            self.error = "Unable to validate account. Please try again."
            validationResult = nil
            Logger.transfer.error("Validation failed: \(error.localizedDescription)")
        }
    }

    @MainActor
    func saveBeneficiary() async {
        guard canSave else { return }

        isSaving = true
        error = nil
        defer { isSaving = false }

        do {
            if let existing = existingBeneficiary {
                // Update existing
                let request = UpdateBeneficiaryRequest(
                    name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                    accountNumber: accountNumber,
                    iban: beneficiaryType == .international ? iban : nil,
                    type: beneficiaryType,
                    isFavorite: isFavorite
                )

                _ = try await beneficiaryService.updateBeneficiary(id: existing.id, request: request)
                Logger.transfer.debug("Updated beneficiary: \(self.name)")
            } else {
                // Add new
                let request = AddBeneficiaryRequest(
                    name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                    accountNumber: accountNumber,
                    iban: beneficiaryType == .international ? iban : nil,
                    type: beneficiaryType,
                    isFavorite: isFavorite
                )

                _ = try await beneficiaryService.addBeneficiary(request)
                Logger.transfer.debug("Added new beneficiary: \(self.name)")
            }

            coordinator?.pop()
        } catch {
            self.error = "Unable to save beneficiary. Please try again."
            Logger.transfer.error("Save failed: \(error.localizedDescription)")
        }
    }

    func cancel() {
        coordinator?.pop()
    }

    func clearValidation() {
        // Clear validation when account number changes (unless unchanged from original in edit mode)
        if accountNumber != originalAccountNumber || !isEditMode {
            validationResult = nil
        }
    }

    func onAccountNumberChanged() {
        clearValidation()
    }

    func onBeneficiaryTypeChanged() {
        // Clear validation when type changes since it affects bank lookup
        validationResult = nil
    }
}
