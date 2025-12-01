import Foundation

protocol BeneficiaryServiceProtocol {
    func fetchBeneficiaries() async throws -> [Beneficiary]
    func addBeneficiary(_ request: AddBeneficiaryRequest) async throws -> Beneficiary
    func updateBeneficiary(id: String, request: UpdateBeneficiaryRequest) async throws -> Beneficiary
    func deleteBeneficiary(id: String) async throws
    func validateBeneficiary(_ request: ValidateBeneficiaryRequest) async throws -> BeneficiaryValidation
    func toggleFavorite(id: String) async throws -> Beneficiary
}
