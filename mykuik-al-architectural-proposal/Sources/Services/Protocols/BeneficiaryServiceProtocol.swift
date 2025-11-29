import Foundation

protocol BeneficiaryServiceProtocol {
    func fetchBeneficiaries() async throws -> [Beneficiary]
    func addBeneficiary(request: BeneficiaryRequest) async throws -> Beneficiary
    func updateBeneficiary(id: String, updates: BeneficiaryUpdates) async throws -> Beneficiary
    func deleteBeneficiary(id: String) async throws
    func validateBeneficiary(request: BeneficiaryRequest) async throws -> BeneficiaryValidation
    func toggleFavorite(id: String) async throws -> Beneficiary
}
