import Foundation

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
