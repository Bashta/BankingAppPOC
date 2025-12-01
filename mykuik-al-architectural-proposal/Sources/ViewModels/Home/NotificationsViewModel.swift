import Foundation
import Combine
import OSLog

// MARK: - NotificationsViewModel

/// ViewModel for the Notifications List screen.
///
/// Responsibilities:
/// - Manages notification list state including loading, refreshing, and errors
/// - Groups notifications by date (Today, Yesterday, Older)
/// - Handles mark as read operations with optimistic updates
/// - Routes notification taps to appropriate screens via coordinator
///
/// Architecture:
/// - Uses @MainActor for thread-safe UI state updates
/// - Weak coordinator reference prevents retain cycles
/// - Optimistic updates for immediate UI feedback
final class NotificationsViewModel: ObservableObject {

    // MARK: - Published State (AC1)

    /// All notifications fetched from the service
    @Published var notifications: [BankNotification] = []

    /// Initial loading state
    @Published var isLoading = false

    /// Pull-to-refresh state
    @Published var isRefreshing = false

    /// Error state for displaying error view
    @Published var error: Error?

    /// Controls visibility of "Mark All as Read" confirmation alert
    @Published var showMarkAllConfirmation = false

    // MARK: - Dependencies (AC1)

    private let notificationService: NotificationServiceProtocol
    private weak var coordinator: HomeCoordinator?

    // MARK: - Initialization

    /// Creates NotificationsViewModel with service and coordinator.
    ///
    /// - Parameters:
    ///   - notificationService: Service for notification operations
    ///   - coordinator: HomeCoordinator for navigation (weak reference)
    init(
        notificationService: NotificationServiceProtocol,
        coordinator: HomeCoordinator
    ) {
        self.notificationService = notificationService
        self.coordinator = coordinator
    }

    // MARK: - Data Loading (AC2)

    /// Loads notifications from the service.
    ///
    /// Sets isLoading = true during fetch, updates notifications array,
    /// and handles errors by setting the error property.
    @MainActor
    func loadData() async {
        isLoading = true
        error = nil

        defer { isLoading = false }

        do {
            let fetchedNotifications = try await notificationService.fetchNotifications()
            self.notifications = fetchedNotifications
            Logger.home.debug("Loaded \(fetchedNotifications.count) notifications")
        } catch {
            self.error = error
            Logger.home.error("Failed to load notifications: \(error.localizedDescription)")
        }
    }

    // MARK: - Refresh (AC3)

    /// Refreshes notifications (pull-to-refresh).
    ///
    /// Uses isRefreshing flag for refresh indicator.
    @MainActor
    func refresh() async {
        isRefreshing = true

        defer { isRefreshing = false }

        do {
            let fetchedNotifications = try await notificationService.fetchNotifications()
            self.notifications = fetchedNotifications
            Logger.home.debug("Refreshed notifications: \(fetchedNotifications.count) items")
        } catch {
            self.error = error
            Logger.home.error("Failed to refresh notifications: \(error.localizedDescription)")
        }
    }

    // MARK: - Notification Grouping (AC5)

    /// Returns notifications grouped by date: Today, Yesterday, Older.
    ///
    /// Uses Calendar for date comparison. Groups are sorted by date descending
    /// within each group.
    var groupedNotifications: [NotificationGroup] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        var todayNotifications: [BankNotification] = []
        var yesterdayNotifications: [BankNotification] = []
        var olderNotifications: [BankNotification] = []

        for notification in notifications {
            let notificationDay = calendar.startOfDay(for: notification.date)
            let daysDifference = calendar.dateComponents([.day], from: notificationDay, to: today).day ?? 0

            if daysDifference == 0 {
                todayNotifications.append(notification)
            } else if daysDifference == 1 {
                yesterdayNotifications.append(notification)
            } else {
                olderNotifications.append(notification)
            }
        }

        // Sort each group by date descending (newest first)
        todayNotifications.sort { $0.date > $1.date }
        yesterdayNotifications.sort { $0.date > $1.date }
        olderNotifications.sort { $0.date > $1.date }

        var groups: [NotificationGroup] = []

        if !todayNotifications.isEmpty {
            groups.append(NotificationGroup(title: "Today", notifications: todayNotifications))
        }

        if !yesterdayNotifications.isEmpty {
            groups.append(NotificationGroup(title: "Yesterday", notifications: yesterdayNotifications))
        }

        if !olderNotifications.isEmpty {
            groups.append(NotificationGroup(title: "Older", notifications: olderNotifications))
        }

        return groups
    }

    /// Returns true if any notification is unread.
    /// Used to enable/disable "Mark All as Read" button.
    var hasUnreadNotifications: Bool {
        notifications.contains { !$0.isRead }
    }

    // MARK: - Mark as Read (AC4)

    /// Marks a single notification as read with optimistic update.
    ///
    /// Pattern:
    /// 1. Return early if already read
    /// 2. Optimistically update local state
    /// 3. Call service
    /// 4. On error: rollback and show error
    ///
    /// - Parameter notification: The notification to mark as read
    @MainActor
    func markAsRead(_ notification: BankNotification) async {
        // Return early if already read
        guard !notification.isRead else { return }

        // Find index for optimistic update
        guard let index = notifications.firstIndex(where: { $0.id == notification.id }) else {
            return
        }

        // Optimistic update
        notifications[index].isRead = true
        Logger.home.debug("Optimistically marked notification \(notification.id) as read")

        do {
            try await notificationService.markAsRead(id: notification.id)
            Logger.home.info("Successfully marked notification \(notification.id) as read")
        } catch {
            // Rollback on error
            notifications[index].isRead = false
            self.error = error
            Logger.home.error("Failed to mark notification as read: \(error.localizedDescription)")
        }
    }

    /// Marks all notifications as read.
    ///
    /// Calls service first, then updates local state.
    /// On error: reloads data to sync state.
    @MainActor
    func markAllAsRead() async {
        do {
            try await notificationService.markAllAsRead()

            // Update all local notifications
            for index in notifications.indices {
                notifications[index].isRead = true
            }

            Logger.home.info("Successfully marked all \(self.notifications.count) notifications as read")
        } catch {
            // On error, reload to sync state
            self.error = error
            await loadData()
            Logger.home.error("Failed to mark all as read: \(error.localizedDescription)")
        }
    }

    /// Shows the "Mark All as Read" confirmation alert.
    func showMarkAllConfirmationAlert() {
        showMarkAllConfirmation = true
    }

    /// Dismisses the "Mark All as Read" confirmation alert.
    func dismissMarkAllConfirmation() {
        showMarkAllConfirmation = false
    }

    // MARK: - Navigation (AC6)

    /// Handles notification tap based on notification type.
    ///
    /// Navigation rules:
    /// - .transaction with relatedEntityId: Navigate to transaction detail (cross-feature to Accounts)
    /// - .security: Navigate to security settings (cross-feature to More)
    /// - .promotion, .system: No navigation (inline display)
    ///
    /// Always marks the notification as read first (if unread).
    ///
    /// - Parameter notification: The tapped notification
    func handleNotificationTap(_ notification: BankNotification) {
        // Mark as read first (fire and forget)
        Task {
            await markAsRead(notification)
        }

        Logger.home.debug("Handling tap on notification: \(notification.id), type: \(notification.type.rawValue)")

        switch notification.type {
        case .transaction:
            if let transactionId = notification.relatedEntityId {
                Logger.home.info("Navigating to transaction detail: \(transactionId)")
                coordinator?.navigateToTransactionDetail(transactionId: transactionId)
            }

        case .security:
            Logger.home.info("Navigating to security settings")
            coordinator?.navigateToSecuritySettings()

        case .promotion, .system:
            // No navigation - content shown inline
            Logger.home.debug("No navigation for notification type: \(notification.type.rawValue)")
        }
    }
}
