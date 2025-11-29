import Foundation

protocol AccountServiceProtocol {
    func fetchAccounts() async throws -> [Account]
    func fetchAccount(id: String) async throws -> Account
    func updateAccount(id: String, updates: AccountUpdates) async throws -> Account
    func setDefaultAccount(id: String) async throws
}
