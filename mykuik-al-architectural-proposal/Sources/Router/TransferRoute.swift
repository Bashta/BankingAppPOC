import Foundation

// MARK: - TransferRoute

enum TransferRoute: Route {
    case home
    case internalTransfer
    case internalTransferWithAccount(fromAccountId: String)
    case externalTransfer
    case beneficiaryList
    case addBeneficiary
    case editBeneficiary(beneficiaryId: String)
    case confirm(request: TransferRequest)
    case confirmation(transferId: String)
    case receipt(transferId: String)

    var id: String {
        switch self {
        case .home:
            "transfer-home"
        case .internalTransfer:
            "transfer-internalTransfer"
        case .internalTransferWithAccount(let fromAccountId):
            "transfer-internalTransfer-\(fromAccountId)"
        case .externalTransfer:
            "transfer-externalTransfer"
        case .beneficiaryList:
            "transfer-beneficiaryList"
        case .addBeneficiary:
            "transfer-addBeneficiary"
        case .editBeneficiary(let beneficiaryId):
            "transfer-editBeneficiary-\(beneficiaryId)"
        case .confirm(let request):
            "transfer-confirm-\(request.id)"
        case .confirmation(let transferId):
            "transfer-confirmation-\(transferId)"
        case .receipt(let transferId):
            "transfer-receipt-\(transferId)"
        }
    }
}

// MARK: - TransferRoute Parser

extension TransferRoute {
    static func parse(_ components: [String]) -> Result<AppRoute, DeepLinkError> {
        guard !components.isEmpty, components[0] == "transfer" else {
            return .failure(.invalidPath)
        }

        if components.count == 1 {
            return .success(.transfer(.home))
        } else if components.count == 2 {
            if components[1] == "internal" {
                return .success(.transfer(.internalTransfer))
            } else if components[1] == "external" {
                return .success(.transfer(.externalTransfer))
            } else if components[1] == "beneficiaries" {
                return .success(.transfer(.beneficiaryList))
            }
        } else if components.count == 3 {
            if components[1] == "internal" {
                return .success(.transfer(.internalTransferWithAccount(fromAccountId: components[2])))
            } else if components[1] == "beneficiaries" && components[2] == "add" {
                return .success(.transfer(.addBeneficiary))
            } else if components[1] == "confirmation" {
                return .success(.transfer(.confirmation(transferId: components[2])))
            } else if components[1] == "receipt" {
                return .success(.transfer(.receipt(transferId: components[2])))
            }
        }

        return .failure(.invalidPath)
    }
}
