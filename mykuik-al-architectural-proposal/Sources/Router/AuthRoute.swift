import Foundation

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

// MARK: - AuthRoute Parser

extension AuthRoute {
    static func parse(_ components: [String]) -> Result<AppRoute, DeepLinkError> {
        guard !components.isEmpty, components[0] == "auth" else {
            return .failure(.invalidPath)
        }

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
