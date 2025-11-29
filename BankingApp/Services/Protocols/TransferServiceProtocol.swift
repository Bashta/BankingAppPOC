import Foundation

protocol TransferServiceProtocol {
    func initiateTransfer(request: TransferRequest) async throws -> Transfer
    func confirmTransfer(id: String, otpCode: String) async throws -> Transfer
    func cancelTransfer(id: String) async throws -> Transfer
    func fetchTransferStatus(id: String) async throws -> Transfer
}
