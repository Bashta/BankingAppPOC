import Foundation

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
}

// MARK: - HomeRoute Parser

extension HomeRoute {
    static func parse(_ components: [String]) -> Result<AppRoute, DeepLinkError> {
        guard !components.isEmpty else {
            return .failure(.invalidPath)
        }

        let first = components[0]

        if first == "home" {
            if components.count == 1 {
                return .success(.home(.dashboard))
            }
            return .failure(.invalidPath)
        }

        if first == "notifications" {
            if components.count == 1 {
                return .success(.home(.notifications))
            } else if components.count == 2 {
                return .success(.home(.notificationDetail(notificationId: components[1])))
            }
            return .failure(.invalidPath)
        }

        return .failure(.invalidPath)
    }
}
