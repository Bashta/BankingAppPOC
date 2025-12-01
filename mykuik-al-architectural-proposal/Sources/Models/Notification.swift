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

// MARK: - NotificationGroup Model

struct NotificationGroup: Identifiable {
    let id = UUID()
    let title: String
    let notifications: [BankNotification]
}

// MARK: - NotificationSettings Model

struct NotificationSettings: Hashable, Codable {
    var pushEnabled: Bool
    var emailEnabled: Bool
    var smsEnabled: Bool
    var transactionAlertsEnabled: Bool
    var securityAlertsEnabled: Bool  // Always true - cannot be disabled
    var promotionsEnabled: Bool
    var minimumAlertAmount: Decimal

    static var `default`: NotificationSettings {
        NotificationSettings(
            pushEnabled: true,
            emailEnabled: true,
            smsEnabled: false,
            transactionAlertsEnabled: true,
            securityAlertsEnabled: true,
            promotionsEnabled: false,
            minimumAlertAmount: 0
        )
    }
}
