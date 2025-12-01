import SwiftUI

// MARK: - NotificationsView

/// View displaying the notifications list with grouping, read/unread states, and actions.
///
/// Features:
/// - Grouped notifications by date (Today, Yesterday, Older)
/// - Pull-to-refresh support
/// - "Mark all as read" toolbar button with confirmation
/// - Loading, empty, and error state handling
/// - Navigation to related screens on notification tap
///
/// Architecture:
/// - @ObservedObject for externally-provided ViewModel
/// - Uses .task for initial data load
/// - Uses .refreshable for pull-to-refresh
/// - Uses .alert for confirmation dialog
struct NotificationsView: View {

    // MARK: - Properties

    @ObservedObject var viewModel: NotificationsViewModel

    // MARK: - Body

    var body: some View {
        content
            .navigationTitle("Notifications")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    markAllAsReadButton
                }
            }
            .alert(
                "Mark All as Read?",
                isPresented: $viewModel.showMarkAllConfirmation
            ) {
                Button("Cancel", role: .cancel) {
                    viewModel.dismissMarkAllConfirmation()
                }
                Button("Mark All") {
                    Task {
                        await viewModel.markAllAsRead()
                    }
                }
            } message: {
                Text("This will mark all notifications as read.")
            }
            .task {
                await viewModel.loadData()
            }
    }

    // MARK: - Content

    /// Main content view that switches between states
    @ViewBuilder
    private var content: some View {
        if viewModel.isLoading && viewModel.notifications.isEmpty {
            // Loading state (AC7)
            loadingView
        } else if let error = viewModel.error, viewModel.notifications.isEmpty {
            // Error state (AC12)
            errorView(error: error)
        } else if viewModel.notifications.isEmpty {
            // Empty state (AC11)
            emptyStateView
        } else {
            // Notification list (AC9)
            notificationsList
        }
    }

    // MARK: - Loading State (AC7)

    private var loadingView: some View {
        VStack {
            Spacer()
            LoadingView(message: "Loading notifications...")
            Spacer()
        }
    }

    // MARK: - Error State (AC12)

    private func errorView(error: Error) -> some View {
        VStack {
            Spacer()
            ErrorView(
                message: "Unable to load notifications. Please try again.",
                retryAction: {
                    Task {
                        await viewModel.loadData()
                    }
                }
            )
            Spacer()
        }
    }

    // MARK: - Empty State (AC11)

    private var emptyStateView: some View {
        VStack {
            Spacer()
            EmptyStateView(
                iconName: "bell.slash",
                title: "No Notifications",
                message: "You don't have any notifications yet."
            )
            Spacer()
        }
    }

    // MARK: - Notification List (AC9)

    private var notificationsList: some View {
        List {
            ForEach(viewModel.groupedNotifications) { group in
                Section {
                    ForEach(group.notifications, id: \.id) { notification in
                        NotificationCell(notification: notification) {
                            viewModel.handleNotificationTap(notification)
                        }
                    }
                } header: {
                    Text(group.title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                        .textCase(nil)
                }
            }
        }
        .listStyle(.insetGrouped)
        .refreshable {
            await viewModel.refresh()
        }
    }

    // MARK: - Toolbar Button (AC8)

    private var markAllAsReadButton: some View {
        Button {
            viewModel.showMarkAllConfirmationAlert()
        } label: {
            Text("Mark all as read")
                .font(.subheadline)
        }
        .disabled(!viewModel.hasUnreadNotifications)
    }
}
