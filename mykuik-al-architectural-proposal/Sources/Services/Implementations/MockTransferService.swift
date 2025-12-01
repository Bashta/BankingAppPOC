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

        // Determine destination name based on destination type
        let destinationName: String
        switch request.destinationType {
        case .internalAccount(let accountId):
            destinationName = accountId == "ACC001" ? "Primary Checking" : "Emergency Savings"
        case .beneficiary(let beneficiaryId):
            destinationName = "Beneficiary \(beneficiaryId)"
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
            otpReference: otpRef,
            destinationName: destinationName,
            sourceAccountName: request.sourceAccountId == "ACC001" ? "Primary Checking" : "Emergency Savings"
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
            otpReference: nil,
            destinationName: transfer.destinationName,
            sourceAccountName: transfer.sourceAccountName
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
            otpReference: nil,
            destinationName: transfer.destinationName,
            sourceAccountName: transfer.sourceAccountName
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

    func fetchRecentTransfers(limit: Int) async throws -> [Transfer] {
        try await Task.sleep(nanoseconds: UInt64.random(in: 300_000_000...500_000_000))

        // Return mock transfer history with various statuses
        let mockTransfers: [Transfer] = [
            Transfer(
                id: "TRF001",
                sourceAccountId: "ACC001",
                destinationType: .beneficiary(beneficiaryId: "BEN001"),
                amount: 250.00,
                currency: "ALL",
                description: "Monthly rent payment",
                reference: "REF00000001",
                status: .completed,
                date: Date().addingTimeInterval(-86400), // 1 day ago
                type: .external,
                initiatedDate: Date().addingTimeInterval(-86400),
                completedDate: Date().addingTimeInterval(-86000),
                otpRequired: false,
                otpReference: nil,
                destinationName: "John Smith",
                sourceAccountName: "Primary Checking"
            ),
            Transfer(
                id: "TRF002",
                sourceAccountId: "ACC001",
                destinationType: .internalAccount(accountId: "ACC002"),
                amount: 500.00,
                currency: "ALL",
                description: "Savings deposit",
                reference: "REF00000002",
                status: .completed,
                date: Date().addingTimeInterval(-172800), // 2 days ago
                type: .internal,
                initiatedDate: Date().addingTimeInterval(-172800),
                completedDate: Date().addingTimeInterval(-172400),
                otpRequired: false,
                otpReference: nil,
                destinationName: "Emergency Savings",
                sourceAccountName: "Primary Checking"
            ),
            Transfer(
                id: "TRF003",
                sourceAccountId: "ACC002",
                destinationType: .beneficiary(beneficiaryId: "BEN002"),
                amount: 150.00,
                currency: "ALL",
                description: "Utility payment",
                reference: "REF00000003",
                status: .pending,
                date: Date().addingTimeInterval(-3600), // 1 hour ago
                type: .external,
                initiatedDate: Date().addingTimeInterval(-3600),
                completedDate: nil,
                otpRequired: true,
                otpReference: OTPReference(
                    id: "OTP003",
                    expiresAt: Date().addingTimeInterval(300),
                    purpose: .transfer
                ),
                destinationName: "OSHEE Albania",
                sourceAccountName: "Emergency Savings"
            ),
            Transfer(
                id: "TRF004",
                sourceAccountId: "ACC001",
                destinationType: .beneficiary(beneficiaryId: "BEN003"),
                amount: 75.50,
                currency: "ALL",
                description: "Internet bill",
                reference: "REF00000004",
                status: .failed,
                date: Date().addingTimeInterval(-259200), // 3 days ago
                type: .external,
                initiatedDate: Date().addingTimeInterval(-259200),
                completedDate: nil,
                otpRequired: false,
                otpReference: nil,
                destinationName: "ALBtelecom",
                sourceAccountName: "Primary Checking"
            ),
            Transfer(
                id: "TRF005",
                sourceAccountId: "ACC002",
                destinationType: .internalAccount(accountId: "ACC001"),
                amount: 1000.00,
                currency: "ALL",
                description: "Transfer to checking",
                reference: "REF00000005",
                status: .completed,
                date: Date().addingTimeInterval(-432000), // 5 days ago
                type: .internal,
                initiatedDate: Date().addingTimeInterval(-432000),
                completedDate: Date().addingTimeInterval(-431600),
                otpRequired: false,
                otpReference: nil,
                destinationName: "Primary Checking",
                sourceAccountName: "Emergency Savings"
            )
        ]

        // Return recent transfers (sorted by date, limited)
        let sortedTransfers = mockTransfers.sorted { $0.date > $1.date }
        return Array(sortedTransfers.prefix(limit))
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
