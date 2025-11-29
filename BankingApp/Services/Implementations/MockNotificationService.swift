import Foundation

final class MockNotificationService: NotificationServiceProtocol {
    private var notifications: [BankNotification] = [
        BankNotification(
            id: "NOTIF001",
            type: .transaction,
            title: "Transaction Alert",
            message: "Transaction of $45.99 at Amazon",
            date: Date().addingTimeInterval(-86400 * 1), // 1 day ago
            isRead: false,
            relatedEntityId: "TXN001"
        ),
        BankNotification(
            id: "NOTIF002",
            type: .security,
            title: "Login from New Device",
            message: "We detected a login from a new device. If this wasn't you, please contact us immediately.",
            date: Date().addingTimeInterval(-86400 * 2), // 2 days ago
            isRead: false,
            relatedEntityId: nil
        ),
        BankNotification(
            id: "NOTIF003",
            type: .transaction,
            title: "Salary Credited",
            message: "Your salary of $3,500.00 has been credited to your Primary Checking account.",
            date: Date().addingTimeInterval(-86400 * 3), // 3 days ago
            isRead: true,
            relatedEntityId: "TXN002"
        ),
        BankNotification(
            id: "NOTIF004",
            type: .promotion,
            title: "Limited Time Offer",
            message: "Get 2% cashback on all purchases this month with your credit card!",
            date: Date().addingTimeInterval(-86400 * 4), // 4 days ago
            isRead: true,
            relatedEntityId: nil
        ),
        BankNotification(
            id: "NOTIF005",
            type: .security,
            title: "Password Changed",
            message: "Your password was successfully changed. If you didn't make this change, please contact us.",
            date: Date().addingTimeInterval(-86400 * 5), // 5 days ago
            isRead: true,
            relatedEntityId: nil
        ),
        BankNotification(
            id: "NOTIF006",
            type: .transaction,
            title: "Large Transaction Alert",
            message: "A transaction of $125.80 was made at Walmart.",
            date: Date().addingTimeInterval(-86400 * 6), // 6 days ago
            isRead: true,
            relatedEntityId: "TXN003"
        ),
        BankNotification(
            id: "NOTIF007",
            type: .system,
            title: "System Maintenance",
            message: "Our banking services will be temporarily unavailable on Saturday from 2 AM to 4 AM.",
            date: Date().addingTimeInterval(-86400 * 7), // 7 days ago
            isRead: false,
            relatedEntityId: nil
        )
    ]

    func fetchNotifications() async throws -> [BankNotification] {
        try await Task.sleep(nanoseconds: 200_000_000) // 200ms

        // Return sorted by date (newest first)
        return notifications.sorted { $0.date > $1.date }
    }

    func markAsRead(id: String) async throws {
        try await Task.sleep(nanoseconds: 200_000_000) // 200ms

        guard let index = notifications.firstIndex(where: { $0.id == id }) else {
            throw NotificationError.notificationNotFound
        }

        notifications[index].isRead = true
    }

    func markAllAsRead() async throws {
        try await Task.sleep(nanoseconds: 200_000_000) // 200ms

        for index in notifications.indices {
            notifications[index].isRead = true
        }
    }

    func getUnreadCount() async throws -> Int {
        try await Task.sleep(nanoseconds: 200_000_000) // 200ms

        return notifications.filter { !$0.isRead }.count
    }
}

enum NotificationError: Error {
    case notificationNotFound
}
