import Foundation

// MARK: - CardsRoute

enum CardsRoute: Route {
    case list
    case detail(cardId: String)
    case settings(cardId: String)
    case limits(cardId: String)
    case block(cardId: String, currentStatus: CardStatus, blockReason: BlockReason?)
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
        case .block(let cardId, _, _):
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
        case .block(let cardId, _, _):
            return "cards/\(cardId)/block"
        case .activate(let cardId):
            return "cards/\(cardId)/activate"
        case .pinChange(let cardId):
            return "cards/\(cardId)/pin-change"
        }
    }
}

// MARK: - CardsRoute Parser

extension CardsRoute {
    static func parse(_ components: [String]) -> Result<AppRoute, DeepLinkError> {
        guard !components.isEmpty, components[0] == "cards" else {
            return .failure(.invalidPath)
        }

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
                // Deep links to block default to active card (block mode)
                // The actual card state will be determined when the view loads
                return .success(.cards(.block(cardId: cardId, currentStatus: .active, blockReason: nil)))
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
}
