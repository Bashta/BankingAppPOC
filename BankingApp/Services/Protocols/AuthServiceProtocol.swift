import Foundation
import Combine

protocol AuthServiceProtocol {
    var isAuthenticatedPublisher: AnyPublisher<Bool, Never> { get }
    func login(username: String, password: String) async throws -> LoginResult
    func loginWithBiometric() async throws -> LoginResult
    func verifyOTP(reference: OTPReference, code: String) async throws -> AuthToken
    func logout() async throws
    func forgotPassword(email: String) async throws
    func resetPassword(token: String, newPassword: String) async throws
    func changePassword(oldPassword: String, newPassword: String) async throws
    func changePIN(oldPIN: String, newPIN: String) async throws
}
