import Foundation

// MARK: - BeneficiaryType Enum

enum BeneficiaryType: String, Codable {
    case `internal`
    case external
    case international
}

// MARK: - Beneficiary Model

struct Beneficiary: Identifiable, Hashable, Codable {
    let id: String
    let name: String
    let accountNumber: String
    let iban: String?
    let bankName: String?
    let type: BeneficiaryType
    let isFavorite: Bool
}

// MARK: - BeneficiaryRequest Model

struct BeneficiaryRequest: Hashable, Codable {
    let name: String
    let accountNumber: String
    let iban: String?
    let bankName: String?
    let type: BeneficiaryType
}

// MARK: - BeneficiaryValidation Model

struct BeneficiaryValidation: Hashable, Codable {
    let isValid: Bool
    let bankName: String?
    let accountHolderName: String?
    let errorMessage: String?
}

// MARK: - ValidateBeneficiaryRequest Model

struct ValidateBeneficiaryRequest: Hashable, Codable {
    let accountNumber: String
    let type: BeneficiaryType
}

// MARK: - AddBeneficiaryRequest Model

struct AddBeneficiaryRequest: Hashable, Codable {
    let name: String
    let accountNumber: String
    let iban: String?
    let type: BeneficiaryType
    let isFavorite: Bool
}

// MARK: - UpdateBeneficiaryRequest Model

struct UpdateBeneficiaryRequest: Hashable, Codable {
    let name: String
    let accountNumber: String
    let iban: String?
    let type: BeneficiaryType
    let isFavorite: Bool
}

// MARK: - BeneficiaryUpdates Model

struct BeneficiaryUpdates: Hashable, Codable {
    let name: String?
    let isFavorite: Bool?
}
