import SwiftUI

// MARK: - NotificationCell

/// A cell component displaying a single notification with type icon, title, message, and timestamp.
///
/// Features:
/// - Type-specific SF Symbol icons with colored backgrounds
/// - Bold title for unread notifications, normal weight for read
/// - Message preview (max 2 lines)
/// - Relative timestamp ("2h ago", "Yesterday", etc.)
/// - Blue dot indicator for unread notifications
/// - Proper accessibility labels
///
/// Usage:
/// ```swift
/// NotificationCell(notification: notification) {
///     viewModel.handleNotificationTap(notification)
/// }
/// ```
struct NotificationCell: View {

    // MARK: - Properties

    /// The notification to display
    let notification: BankNotification

    /// Callback invoked when the cell is tapped
    let onTap: () -> Void

    // MARK: - Body

    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .top, spacing: 12) {
                // Type icon with unread indicator overlay
                iconView
                    .overlay(alignment: .topLeading) {
                        unreadIndicator
                    }

                // Content
                VStack(alignment: .leading, spacing: 4) {
                    // Title row with timestamp
                    HStack {
                        Text(notification.title)
                            .font(.subheadline)
                            .fontWeight(notification.isRead ? .regular : .semibold)
                            .foregroundColor(.primary)
                            .lineLimit(1)

                        Spacer()

                        Text(relativeTimeString(from: notification.date))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    // Message preview
                    Text(notification.message)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }
            }
            .padding(.vertical, 8)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint("Double tap to \(accessibilityHint)")
    }

    // MARK: - Subviews

    /// Icon view with type-specific SF Symbol and colored background
    private var iconView: some View {
        Image(systemName: iconName(for: notification.type))
            .font(.system(size: 16, weight: .semibold))
            .foregroundColor(.white)
            .frame(width: 36, height: 36)
            .background(iconBackgroundColor(for: notification.type))
            .clipShape(Circle())
    }

    /// Blue dot indicator shown for unread notifications
    @ViewBuilder
    private var unreadIndicator: some View {
        if !notification.isRead {
            Circle()
                .fill(Color.blue)
                .frame(width: 10, height: 10)
                .offset(x: -2, y: -2)
        }
    }

    // MARK: - Helpers

    /// Returns the SF Symbol name for the notification type.
    ///
    /// - Parameter type: The notification type
    /// - Returns: SF Symbol name string
    private func iconName(for type: NotificationType) -> String {
        switch type {
        case .transaction:
            return "dollarsign.circle.fill"
        case .security:
            return "lock.shield.fill"
        case .promotion:
            return "tag.fill"
        case .system:
            return "bell.fill"
        }
    }

    /// Returns the background color for the notification type icon.
    ///
    /// - Parameter type: The notification type
    /// - Returns: Color for the icon background
    private func iconBackgroundColor(for type: NotificationType) -> Color {
        switch type {
        case .transaction:
            return .green
        case .security:
            return .red
        case .promotion:
            return .orange
        case .system:
            return .blue
        }
    }

    /// Converts a date to a relative time string.
    ///
    /// Examples:
    /// - Within last hour: "Now"
    /// - 1-23 hours ago: "2h ago"
    /// - Yesterday: "Yesterday"
    /// - 2-6 days ago: "3 days ago"
    /// - Older: "Dec 1"
    ///
    /// - Parameter date: The date to format
    /// - Returns: Human-readable relative time string
    private func relativeTimeString(from date: Date) -> String {
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.minute, .hour, .day], from: date, to: now)

        let minutes = components.minute ?? 0
        let hours = components.hour ?? 0
        let days = components.day ?? 0

        if days == 0 {
            if hours == 0 {
                if minutes < 5 {
                    return "Now"
                }
                return "\(minutes)m ago"
            }
            return "\(hours)h ago"
        } else if days == 1 {
            return "Yesterday"
        } else if days < 7 {
            return "\(days) days ago"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d"
            return formatter.string(from: date)
        }
    }

    // MARK: - Accessibility

    /// Combined accessibility label for the notification
    private var accessibilityLabel: String {
        let readStatus = notification.isRead ? "Read" : "Unread"
        let timeAgo = relativeTimeString(from: notification.date)
        return "\(readStatus) \(notification.type.rawValue) notification: \(notification.title). \(notification.message). \(timeAgo)"
    }

    /// Accessibility hint describing the action
    private var accessibilityHint: String {
        switch notification.type {
        case .transaction:
            return "view transaction details"
        case .security:
            return "view security settings"
        case .promotion, .system:
            return "mark as read"
        }
    }
}

// MARK: - Preview

#if DEBUG
struct NotificationCell_Previews: PreviewProvider {
    static var previews: some View {
        List {
            NotificationCell(
                notification: BankNotification(
                    id: "1",
                    type: .transaction,
                    title: "Transaction Alert",
                    message: "Transaction of $45.99 at Amazon has been processed successfully.",
                    date: Date().addingTimeInterval(-3600 * 2),
                    isRead: false,
                    relatedEntityId: "TXN001"
                )
            ) {
                // Tap action
            }

            NotificationCell(
                notification: BankNotification(
                    id: "2",
                    type: .security,
                    title: "Login from New Device",
                    message: "We detected a login from a new device. If this wasn't you, please contact us immediately.",
                    date: Date().addingTimeInterval(-86400),
                    isRead: true,
                    relatedEntityId: nil
                )
            ) {
                // Tap action
            }

            NotificationCell(
                notification: BankNotification(
                    id: "3",
                    type: .promotion,
                    title: "Limited Time Offer",
                    message: "Get 2% cashback on all purchases this month!",
                    date: Date().addingTimeInterval(-86400 * 3),
                    isRead: false,
                    relatedEntityId: nil
                )
            ) {
                // Tap action
            }

            NotificationCell(
                notification: BankNotification(
                    id: "4",
                    type: .system,
                    title: "System Maintenance",
                    message: "Our banking services will be temporarily unavailable on Saturday from 2 AM to 4 AM.",
                    date: Date().addingTimeInterval(-86400 * 7),
                    isRead: true,
                    relatedEntityId: nil
                )
            ) {
                // Tap action
            }
        }
        .previewDisplayName("Notification Cells")
    }
}
#endif
