import Foundation
import SwiftUI

// MARK: - Route Protocol

protocol Route: Hashable, Identifiable {
    var id: String { get }
    var path: String { get }
}

// MARK: - AppRoute

enum AppRoute: Route {
    case home(HomeRoute?)
    case accounts(AccountsRoute?)
    case transfer(TransferRoute?)
    case cards(CardsRoute?)
    case more(MoreRoute?)
    case auth(AuthRoute?)

    var id: String {
        switch self {
        case .home(let route):
            return route?.id ?? "app-home"
        case .accounts(let route):
            return route?.id ?? "app-accounts"
        case .transfer(let route):
            return route?.id ?? "app-transfer"
        case .cards(let route):
            return route?.id ?? "app-cards"
        case .more(let route):
            return route?.id ?? "app-more"
        case .auth(let route):
            return route?.id ?? "app-auth"
        }
    }

    var path: String {
        switch self {
        case .home(let route):
            return route?.path ?? "home"
        case .accounts(let route):
            return route?.path ?? "accounts"
        case .transfer(let route):
            return route?.path ?? "transfer"
        case .cards(let route):
            return route?.path ?? "cards"
        case .more(let route):
            return route?.path ?? "more"
        case .auth(let route):
            return route?.path ?? "auth"
        }
    }
}

// MARK: - HomeRoute

enum HomeRoute: Route {
    case dashboard
    case notifications
    case notificationDetail(notificationId: String)

    var id: String {
        switch self {
        case .dashboard:
            return "home-dashboard"
        case .notifications:
            return "home-notifications"
        case .notificationDetail(let notificationId):
            return "home-notificationDetail-\(notificationId)"
        }
    }

    var path: String {
        switch self {
        case .dashboard:
            return "home"
        case .notifications:
            return "notifications"
        case .notificationDetail(let notificationId):
            return "notifications/\(notificationId)"
        }
    }
}

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

    var path: String {
        switch self {
        case .list:
            return "accounts"
        case .detail(let accountId):
            return "accounts/\(accountId)"
        case .transactions(let accountId):
            return "accounts/\(accountId)/transactions"
        case .transactionDetail(let transactionId):
            return "accounts/transactions/\(transactionId)"
        case .statement(let accountId):
            return "accounts/\(accountId)/statement"
        case .statementDownload(let accountId, let month, let year):
            return "accounts/\(accountId)/statement/\(month)/\(year)"
        }
    }
}

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
            return "transfer-home"
        case .internalTransfer:
            return "transfer-internalTransfer"
        case .internalTransferWithAccount(let fromAccountId):
            return "transfer-internalTransfer-\(fromAccountId)"
        case .externalTransfer:
            return "transfer-externalTransfer"
        case .beneficiaryList:
            return "transfer-beneficiaryList"
        case .addBeneficiary:
            return "transfer-addBeneficiary"
        case .editBeneficiary(let beneficiaryId):
            return "transfer-editBeneficiary-\(beneficiaryId)"
        case .confirm(let request):
            return "transfer-confirm-\(request.id)"
        case .confirmation(let transferId):
            return "transfer-confirmation-\(transferId)"
        case .receipt(let transferId):
            return "transfer-receipt-\(transferId)"
        }
    }

    var path: String {
        switch self {
        case .home:
            return "transfer"
        case .internalTransfer:
            return "transfer/internal"
        case .internalTransferWithAccount(let fromAccountId):
            return "transfer/internal/\(fromAccountId)"
        case .externalTransfer:
            return "transfer/external"
        case .beneficiaryList:
            return "transfer/beneficiaries"
        case .addBeneficiary:
            return "transfer/beneficiaries/add"
        case .editBeneficiary(let beneficiaryId):
            return "transfer/beneficiaries/\(beneficiaryId)/edit"
        case .confirm(let request):
            return "transfer/confirm/\(request.id)"
        case .confirmation(let transferId):
            return "transfer/confirmation/\(transferId)"
        case .receipt(let transferId):
            return "transfer/receipt/\(transferId)"
        }
    }
}

// MARK: - CardsRoute

enum CardsRoute: Route {
    case list
    case detail(cardId: String)
    case settings(cardId: String)
    case limits(cardId: String)
    case block(cardId: String)
    case activate(cardId: String)
    case pinChange(cardId: String)

    var id: String {
        switch self {
        case .list:
            return "cards-list"
        case .detail(let cardId):
            return "cards-detail-\(cardId)"
        case .settings(let cardId):
            return "cards-settings-\(cardId)"
        case .limits(let cardId):
            return "cards-limits-\(cardId)"
        case .block(let cardId):
            return "cards-block-\(cardId)"
        case .activate(let cardId):
            return "cards-activate-\(cardId)"
        case .pinChange(let cardId):
            return "cards-pinChange-\(cardId)"
        }
    }

    var path: String {
        switch self {
        case .list:
            return "cards"
        case .detail(let cardId):
            return "cards/\(cardId)"
        case .settings(let cardId):
            return "cards/\(cardId)/settings"
        case .limits(let cardId):
            return "cards/\(cardId)/limits"
        case .block(let cardId):
            return "cards/\(cardId)/block"
        case .activate(let cardId):
            return "cards/\(cardId)/activate"
        case .pinChange(let cardId):
            return "cards/\(cardId)/pin-change"
        }
    }
}

// MARK: - MoreRoute

enum MoreRoute: Route {
    case menu
    case profile
    case security
    case changePassword
    case changePIN
    case notificationSettings
    case support
    case about

    var id: String {
        switch self {
        case .menu:
            return "more-menu"
        case .profile:
            return "more-profile"
        case .security:
            return "more-security"
        case .changePassword:
            return "more-changePassword"
        case .changePIN:
            return "more-changePIN"
        case .notificationSettings:
            return "more-notificationSettings"
        case .support:
            return "more-support"
        case .about:
            return "more-about"
        }
    }

    var path: String {
        switch self {
        case .menu:
            return "more"
        case .profile:
            return "more/profile"
        case .security:
            return "more/security"
        case .changePassword:
            return "more/security/change-password"
        case .changePIN:
            return "more/security/change-pin"
        case .notificationSettings:
            return "more/notification-settings"
        case .support:
            return "more/support"
        case .about:
            return "more/about"
        }
    }
}

// MARK: - AuthRoute

enum AuthRoute: Route {
    case login
    case biometric
    case otp(reference: String)
    case forgotPassword
    case resetPassword(token: String)
    case sessionExpired

    var id: String {
        switch self {
        case .login:
            return "auth-login"
        case .biometric:
            return "auth-biometric"
        case .otp(let reference):
            return "auth-otp-\(reference)"
        case .forgotPassword:
            return "auth-forgotPassword"
        case .resetPassword(let token):
            return "auth-resetPassword-\(token)"
        case .sessionExpired:
            return "auth-sessionExpired"
        }
    }

    var path: String {
        switch self {
        case .login:
            return "auth/login"
        case .biometric:
            return "auth/biometric"
        case .otp(let reference):
            return "auth/otp/\(reference)"
        case .forgotPassword:
            return "auth/forgot-password"
        case .resetPassword(let token):
            return "auth/reset-password/\(token)"
        case .sessionExpired:
            return "auth/session-expired"
        }
    }
}

// MARK: - NavigationItem

struct NavigationItem: Identifiable, Equatable {
    let id: UUID
    let route: AnyHashable

    init<R: Route>(_ route: R) {
        self.id = UUID()
        self.route = AnyHashable(route)
    }

    static func == (lhs: NavigationItem, rhs: NavigationItem) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - DeepLinkError

enum DeepLinkError: Error, LocalizedError {
    case invalidScheme
    case invalidPath
    case missingParameter(String)
    case unknown

    var errorDescription: String? {
        switch self {
        case .invalidScheme:
            return "Invalid URL scheme. Expected 'bankapp://'."
        case .invalidPath:
            return "Invalid URL path. The provided path does not match any known route."
        case .missingParameter(let parameter):
            return "Missing required parameter: \(parameter)"
        case .unknown:
            return "An unknown error occurred while parsing the deep link."
        }
    }
}

// MARK: - DeepLinkParser

struct DeepLinkParser {
    static func parse(_ url: URL) -> Result<AppRoute, DeepLinkError> {
        // 1. Validate scheme
        guard url.scheme == "bankapp" else {
            return .failure(.invalidScheme)
        }

        // 2. Extract path components (filter out "/" components)
        let components = url.pathComponents.filter { $0 != "/" }

        // 3. Guard against empty path
        guard !components.isEmpty else {
            return .failure(.invalidPath)
        }

        // 4. Match patterns using first component
        let first = components[0]

        switch first {
        case "home":
            return parseHomeRoute(components)
        case "notifications":
            return parseNotificationRoute(components)
        case "accounts":
            return parseAccountsRoute(components)
        case "transfer":
            return parseTransferRoute(components)
        case "cards":
            return parseCardsRoute(components)
        case "more":
            return parseMoreRoute(components)
        case "auth":
            return parseAuthRoute(components)
        default:
            return .failure(.invalidPath)
        }
    }

    // MARK: - Home Routes

    private static func parseHomeRoute(_ components: [String]) -> Result<AppRoute, DeepLinkError> {
        if components.count == 1 {
            return .success(.home(.dashboard))
        }
        return .failure(.invalidPath)
    }

    private static func parseNotificationRoute(_ components: [String]) -> Result<AppRoute, DeepLinkError> {
        if components.count == 1 {
            return .success(.home(.notifications))
        } else if components.count == 2 {
            return .success(.home(.notificationDetail(notificationId: components[1])))
        }
        return .failure(.invalidPath)
    }

    // MARK: - Accounts Routes

    private static func parseAccountsRoute(_ components: [String]) -> Result<AppRoute, DeepLinkError> {
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

    // MARK: - Transfer Routes

    private static func parseTransferRoute(_ components: [String]) -> Result<AppRoute, DeepLinkError> {
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

    // MARK: - Cards Routes

    private static func parseCardsRoute(_ components: [String]) -> Result<AppRoute, DeepLinkError> {
        if components.count == 1 {
            return .success(.cards(.list))
        } else if components.count == 2 {
            return .success(.cards(.detail(cardId: components[1])))
        } else if components.count == 3 {
            let cardId = components[1]
            switch components[2] {
            case "settings":
                return .success(.cards(.settings(cardId: cardId)))
            case "limits":
                return .success(.cards(.limits(cardId: cardId)))
            case "block":
                return .success(.cards(.block(cardId: cardId)))
            case "activate":
                return .success(.cards(.activate(cardId: cardId)))
            case "pin-change":
                return .success(.cards(.pinChange(cardId: cardId)))
            default:
                return .failure(.invalidPath)
            }
        }
        return .failure(.invalidPath)
    }

    // MARK: - More Routes

    private static func parseMoreRoute(_ components: [String]) -> Result<AppRoute, DeepLinkError> {
        if components.count == 1 {
            return .success(.more(.menu))
        } else if components.count == 2 {
            switch components[1] {
            case "profile":
                return .success(.more(.profile))
            case "security":
                return .success(.more(.security))
            case "notification-settings":
                return .success(.more(.notificationSettings))
            case "support":
                return .success(.more(.support))
            case "about":
                return .success(.more(.about))
            default:
                return .failure(.invalidPath)
            }
        } else if components.count == 3 {
            if components[1] == "security" {
                if components[2] == "change-password" {
                    return .success(.more(.changePassword))
                } else if components[2] == "change-pin" {
                    return .success(.more(.changePIN))
                }
            }
        }
        return .failure(.invalidPath)
    }

    // MARK: - Auth Routes

    private static func parseAuthRoute(_ components: [String]) -> Result<AppRoute, DeepLinkError> {
        if components.count == 2 {
            switch components[1] {
            case "login":
                return .success(.auth(.login))
            case "biometric":
                return .success(.auth(.biometric))
            case "forgot-password":
                return .success(.auth(.forgotPassword))
            case "session-expired":
                return .success(.auth(.sessionExpired))
            default:
                return .failure(.invalidPath)
            }
        } else if components.count == 3 {
            if components[1] == "otp" {
                return .success(.auth(.otp(reference: components[2])))
            } else if components[1] == "reset-password" {
                return .success(.auth(.resetPassword(token: components[2])))
            }
        }
        return .failure(.invalidPath)
    }
}
