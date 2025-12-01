import Foundation

// MARK: - Route Protocol

protocol Route: Hashable, Identifiable {
    var id: String { get }
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
