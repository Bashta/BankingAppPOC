import Foundation

final class MockBeneficiaryService: BeneficiaryServiceProtocol {
    private var beneficiaries: [Beneficiary] = [
        Beneficiary(
            id: "BEN001",
            name: "Jane Smith",
            accountNumber: "9876543210",
            iban: "US12CHAS98765432101234",
            bankName: "Chase Bank",
            type: .external,
            isFavorite: true
        ),
        Beneficiary(
            id: "BEN002",
            name: "Robert Johnson",
            accountNumber: "5544332211",
            iban: "US12BOFA55443322111234",
            bankName: "Bank of America",
            type: .external,
            isFavorite: false
        ),
        Beneficiary(
            id: "BEN003",
            name: "Emily Davis",
            accountNumber: "1122334455",
            iban: "US12WFAR11223344551234",
            bankName: "Wells Fargo",
            type: .external,
            isFavorite: true
        ),
        Beneficiary(
            id: "BEN004",
            name: "Michael Brown",
            accountNumber: "6677889900",
            iban: "US12CITI66778899001234",
            bankName: "Citibank",
            type: .external,
            isFavorite: false
        ),
        Beneficiary(
            id: "BEN005",
            name: "Sarah Wilson",
            accountNumber: "3344556677",
            iban: "US12USBA33445566771234",
            bankName: "US Bank",
            type: .external,
            isFavorite: false
        ),
        Beneficiary(
            id: "BEN006",
            name: "David Martinez",
            accountNumber: "8899001122",
            iban: "US12PNCB88990011221234",
            bankName: "PNC Bank",
            type: .external,
            isFavorite: true
        )
    ]

    func fetchBeneficiaries() async throws -> [Beneficiary] {
        try await Task.sleep(nanoseconds: UInt64.random(in: 300_000_000...500_000_000))
        return beneficiaries
    }

    func addBeneficiary(request: BeneficiaryRequest) async throws -> Beneficiary {
        try await Task.sleep(nanoseconds: UInt64.random(in: 300_000_000...500_000_000))

        let newBeneficiary = Beneficiary(
            id: "BEN\(String(format: "%03d", beneficiaries.count + 1))",
            name: request.name,
            accountNumber: request.accountNumber,
            iban: request.iban,
            bankName: request.bankName,
            type: request.type,
            isFavorite: false
        )

        beneficiaries.append(newBeneficiary)
        return newBeneficiary
    }

    func updateBeneficiary(id: String, updates: BeneficiaryUpdates) async throws -> Beneficiary {
        try await Task.sleep(nanoseconds: UInt64.random(in: 300_000_000...500_000_000))

        guard let index = beneficiaries.firstIndex(where: { $0.id == id }) else {
            throw BeneficiaryError.beneficiaryNotFound
        }

        let beneficiary = beneficiaries[index]

        let updatedBeneficiary = Beneficiary(
            id: beneficiary.id,
            name: updates.name ?? beneficiary.name,
            accountNumber: beneficiary.accountNumber,
            iban: beneficiary.iban,
            bankName: beneficiary.bankName,
            type: beneficiary.type,
            isFavorite: updates.isFavorite ?? beneficiary.isFavorite
        )

        beneficiaries[index] = updatedBeneficiary
        return updatedBeneficiary
    }

    func deleteBeneficiary(id: String) async throws {
        try await Task.sleep(nanoseconds: UInt64.random(in: 300_000_000...500_000_000))

        guard let index = beneficiaries.firstIndex(where: { $0.id == id }) else {
            throw BeneficiaryError.beneficiaryNotFound
        }

        beneficiaries.remove(at: index)
    }

    func validateBeneficiary(request: BeneficiaryRequest) async throws -> BeneficiaryValidation {
        try await Task.sleep(nanoseconds: UInt64.random(in: 300_000_000...500_000_000))

        // Simulate bank lookup - return bank name for valid accounts
        let validBanks = ["Chase Bank", "Bank of America", "Wells Fargo", "Citibank", "US Bank"]

        let isValid = request.bankName.map { validBanks.contains($0) } ?? false && request.accountNumber.count == 10

        return BeneficiaryValidation(
            isValid: isValid,
            accountHolderName: isValid ? "Account Holder" : nil
        )
    }

    func toggleFavorite(id: String) async throws -> Beneficiary {
        try await Task.sleep(nanoseconds: 300_000_000) // 300ms

        guard let index = beneficiaries.firstIndex(where: { $0.id == id }) else {
            throw BeneficiaryError.beneficiaryNotFound
        }

        let beneficiary = beneficiaries[index]
        let updatedBeneficiary = Beneficiary(
            id: beneficiary.id,
            name: beneficiary.name,
            accountNumber: beneficiary.accountNumber,
            iban: beneficiary.iban,
            bankName: beneficiary.bankName,
            type: beneficiary.type,
            isFavorite: !beneficiary.isFavorite
        )
        beneficiaries[index] = updatedBeneficiary

        return updatedBeneficiary
    }
}

enum BeneficiaryError: Error {
    case beneficiaryNotFound
    case invalidAccountNumber
    case duplicateBeneficiary
}
