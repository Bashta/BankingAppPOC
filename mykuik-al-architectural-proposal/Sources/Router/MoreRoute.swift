import Foundation

// MARK: - MoreRoute

enum MoreRoute: Route {
    case menu
    case profile
    case editProfile
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
        case .editProfile:
            return "more-editProfile"
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
}

// MARK: - MoreRoute Parser

extension MoreRoute {
    static func parse(_ components: [String]) -> Result<AppRoute, DeepLinkError> {
        guard !components.isEmpty, components[0] == "more" else {
            return .failure(.invalidPath)
        }

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
            } else if components[1] == "profile" && components[2] == "edit" {
                return .success(.more(.editProfile))
            }
        }

        return .failure(.invalidPath)
    }
}
