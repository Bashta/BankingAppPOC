import Foundation

final class MockTransferService: TransferServiceProtocol {
    private var transfers: [Transfer] = []
    private var nextReferenceNumber = 1

    func initiateTransfer(request: TransferRequest) async throws -> Transfer {
        try await Task.sleep(nanoseconds: UInt64.random(in: 300_000_000...500_000_000))

        let reference = "REF\(String(format: "%08d", nextReferenceNumber))"
        nextReferenceNumber += 1

        let otpRef = OTPReference(
            id: UUID().uuidString,
            expiresAt: Date().addingTimeInterval(300), // 5 minutes
            purpose: .transfer
        )

        let transferType: TransferType
        switch request.destinationType {
        case .internalAccount:
            transferType = .internal
        case .beneficiary:
            transferType = .external
        }

        let transfer = Transfer(
            id: UUID().uuidString,
            sourceAccountId: request.sourceAccountId,
            destinationType: request.destinationType,
            amount: request.amount,
            currency: request.currency,
            description: request.description,
            reference: reference,
            status: .initiated,
            date: Date(),
            type: transferType,
            initiatedDate: Date(),
            completedDate: nil,
            otpRequired: true,
            otpReference: otpRef
        )

        transfers.append(transfer)
        return transfer
    }

    func confirmTransfer(id: String, otpCode: String) async throws -> Transfer {
        try await Task.sleep(nanoseconds: 500_000_000) // 500ms for OTP verification

        guard let index = transfers.firstIndex(where: { $0.id == id }) else {
            throw TransferError.transferNotFound
        }

        guard otpCode == "123456" else {
            throw TransferError.invalidOTP
        }

        let transfer = transfers[index]

        guard transfer.status == .initiated || transfer.status == .pending else {
            throw TransferError.invalidStatus
        }

        let updatedTransfer = Transfer(
            id: transfer.id,
            sourceAccountId: transfer.sourceAccountId,
            destinationType: transfer.destinationType,
            amount: transfer.amount,
            currency: transfer.currency,
            description: transfer.description,
            reference: transfer.reference,
            status: .completed,
            date: transfer.date,
            type: transfer.type,
            initiatedDate: transfer.initiatedDate,
            completedDate: Date(),
            otpRequired: false,
            otpReference: nil
        )
        transfers[index] = updatedTransfer

        return updatedTransfer
    }

    func cancelTransfer(id: String) async throws -> Transfer {
        try await Task.sleep(nanoseconds: UInt64.random(in: 300_000_000...500_000_000))

        guard let index = transfers.firstIndex(where: { $0.id == id }) else {
            throw TransferError.transferNotFound
        }

        let transfer = transfers[index]

        guard transfer.status != .completed else {
            throw TransferError.cannotCancelCompleted
        }

        let updatedTransfer = Transfer(
            id: transfer.id,
            sourceAccountId: transfer.sourceAccountId,
            destinationType: transfer.destinationType,
            amount: transfer.amount,
            currency: transfer.currency,
            description: transfer.description,
            reference: transfer.reference,
            status: .cancelled,
            date: transfer.date,
            type: transfer.type,
            initiatedDate: transfer.initiatedDate,
            completedDate: nil,
            otpRequired: false,
            otpReference: nil
        )
        transfers[index] = updatedTransfer

        return updatedTransfer
    }

    func fetchTransferStatus(id: String) async throws -> Transfer {
        try await Task.sleep(nanoseconds: UInt64.random(in: 300_000_000...500_000_000))

        guard let transfer = transfers.first(where: { $0.id == id }) else {
            throw TransferError.transferNotFound
        }

        return transfer
    }
}

enum TransferError: Error {
    case transferNotFound
    case invalidOTP
    case insufficientFunds
    case invalidAmount
    case invalidStatus
    case cannotCancelCompleted
}
