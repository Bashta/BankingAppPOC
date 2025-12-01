import Foundation

protocol AccountServiceProtocol {
    func fetchAccounts() async throws -> [Account]
    func fetchAccount(id: String) async throws -> Account
    func setDefaultAccount(id: String) async throws
    func generateStatement(accountId: String, month: Int, year: Int) async throws -> URL
}
