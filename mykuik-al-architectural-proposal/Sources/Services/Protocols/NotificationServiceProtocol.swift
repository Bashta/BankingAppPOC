import Foundation

protocol NotificationServiceProtocol {
    func fetchNotifications() async throws -> [BankNotification]
    func markAsRead(id: String) async throws
    func markAllAsRead() async throws
    func getUnreadCount() async throws -> Int

    // Notification settings methods
    func fetchSettings() async throws -> NotificationSettings
    func updateSettings(_ settings: NotificationSettings) async throws
}
