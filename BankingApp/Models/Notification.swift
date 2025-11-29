import Foundation

// MARK: - NotificationType Enum

enum NotificationType: String, Codable {
    case transaction
    case security
    case promotion
    case system
}

// MARK: - BankNotification Model

struct BankNotification: Identifiable, Hashable, Codable {
    let id: String
    let type: NotificationType
    let title: String
    let message: String
    let date: Date
    var isRead: Bool
    let relatedEntityId: String?
}

// MARK: - NotificationSettings Model

struct NotificationSettings: Hashable, Codable {
    let enablePush: Bool
    let enableEmail: Bool
    let enableSMS: Bool
    let transactionMinAmount: Decimal
}
