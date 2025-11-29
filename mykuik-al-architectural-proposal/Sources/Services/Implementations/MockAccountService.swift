import Foundation

final class MockAccountService: AccountServiceProtocol {
    private var accounts: [Account] = [
        Account(
            id: "ACC001",
            accountNumber: "1234567890",
            accountType: .checking,
            currency: "USD",
            balance: 5432.50,
            availableBalance: 5232.50,
            accountName: "Primary Checking",
            iban: "US12345678901234567890",
            isDefault: true
        ),
        Account(
            id: "ACC002",
            accountNumber: "0987654321",
            accountType: .savings,
            currency: "USD",
            balance: 15000.00,
            availableBalance: 15000.00,
            accountName: "Emergency Savings",
            iban: "US09876543210987654321",
            isDefault: false
        ),
        Account(
            id: "ACC003",
            accountNumber: "5555666677",
            accountType: .deposit,
            currency: "USD",
            balance: 25000.00,
            availableBalance: 0.00,
            accountName: "Fixed Deposit",
            iban: "US55556666775555666677",
            isDefault: false
        ),
        Account(
            id: "ACC004",
            accountNumber: "7788990011",
            accountType: .checking,
            currency: "USD",
            balance: 892.35,
            availableBalance: 692.35,
            accountName: "Business Account",
            iban: "US77889900117788990011",
            isDefault: false
        )
    ]

    func fetchAccounts() async throws -> [Account] {
        try await Task.sleep(nanoseconds: UInt64.random(in: 300_000_000...500_000_000))
        return accounts
    }

    func fetchAccount(id: String) async throws -> Account {
        try await Task.sleep(nanoseconds: UInt64.random(in: 300_000_000...500_000_000))
        guard let account = accounts.first(where: { $0.id == id }) else {
            throw AccountError.accountNotFound
        }
        return account
    }

    func updateAccount(id: String, updates: AccountUpdates) async throws -> Account {
        try await Task.sleep(nanoseconds: UInt64.random(in: 300_000_000...500_000_000))
        guard let index = accounts.firstIndex(where: { $0.id == id }) else {
            throw AccountError.accountNotFound
        }

        let account = accounts[index]

        let updatedAccount = Account(
            id: account.id,
            accountNumber: account.accountNumber,
            accountType: account.accountType,
            currency: account.currency,
            balance: account.balance,
            availableBalance: account.availableBalance,
            accountName: updates.accountName ?? account.accountName,
            iban: account.iban,
            isDefault: updates.isDefault ?? account.isDefault
        )

        accounts[index] = updatedAccount
        return updatedAccount
    }

    func setDefaultAccount(id: String) async throws {
        try await Task.sleep(nanoseconds: UInt64.random(in: 300_000_000...500_000_000))
        guard accounts.contains(where: { $0.id == id }) else {
            throw AccountError.accountNotFound
        }

        // Update all accounts with new isDefault status
        accounts = accounts.map { account in
            Account(
                id: account.id,
                accountNumber: account.accountNumber,
                accountType: account.accountType,
                currency: account.currency,
                balance: account.balance,
                availableBalance: account.availableBalance,
                accountName: account.accountName,
                iban: account.iban,
                isDefault: account.id == id
            )
        }
    }
}

enum AccountError: Error {
    case accountNotFound
    case insufficientBalance
    case invalidAccountNumber
}
