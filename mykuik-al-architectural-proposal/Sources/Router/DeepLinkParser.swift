import Foundation

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

        // 4. Delegate to feature-specific parsers based on first component
        let first = components[0]

        switch first {
        case "home", "notifications":
            return HomeRoute.parse(components)
        case "accounts":
            return AccountsRoute.parse(components)
        case "transfer":
            return TransferRoute.parse(components)
        case "cards":
            return CardsRoute.parse(components)
        case "more":
            return MoreRoute.parse(components)
        case "auth":
            return AuthRoute.parse(components)
        default:
            return .failure(.invalidPath)
        }
    }
}
