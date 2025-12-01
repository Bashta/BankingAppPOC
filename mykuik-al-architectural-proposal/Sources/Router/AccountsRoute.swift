import Foundation

// MARK: - AccountsRoute

enum AccountsRoute: Route {
    case list
    case detail(accountId: String)
    case transactions(accountId: String)
    case transactionDetail(transactionId: String)
    case statement(accountId: String)
    case statementDownload(accountId: String, month: Int, year: Int)

    var id: String {
        switch self {
        case .list:
            return "accounts-list"
        case .detail(let accountId):
            return "accounts-detail-\(accountId)"
        case .transactions(let accountId):
            return "accounts-transactions-\(accountId)"
        case .transactionDetail(let transactionId):
            return "accounts-transactionDetail-\(transactionId)"
        case .statement(let accountId):
            return "accounts-statement-\(accountId)"
        case .statementDownload(let accountId, let month, let year):
            return "accounts-statementDownload-\(accountId)-\(month)-\(year)"
        }
    }
}

// MARK: - AccountsRoute Parser

extension AccountsRoute {
    static func parse(_ components: [String]) -> Result<AppRoute, DeepLinkError> {
        guard !components.isEmpty, components[0] == "accounts" else {
            return .failure(.invalidPath)
        }

        if components.count == 1 {
            return .success(.accounts(.list))
        } else if components.count == 2 {
            return .success(.accounts(.detail(accountId: components[1])))
        } else if components.count == 3 {
            if components[2] == "transactions" {
                return .success(.accounts(.transactions(accountId: components[1])))
            } else if components[2] == "statement" {
                return .success(.accounts(.statement(accountId: components[1])))
            } else if components[1] == "transactions" {
                return .success(.accounts(.transactionDetail(transactionId: components[2])))
            }
        } else if components.count == 5 {
            if components[2] == "statement" {
                guard let month = Int(components[3]), let year = Int(components[4]) else {
                    return .failure(.missingParameter("month or year must be integers"))
                }
                return .success(.accounts(.statementDownload(accountId: components[1], month: month, year: year)))
            }
        }

        return .failure(.invalidPath)
    }
}
