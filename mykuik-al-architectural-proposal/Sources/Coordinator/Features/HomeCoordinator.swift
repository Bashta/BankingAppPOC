import Foundation
import SwiftUI
import Combine

// MARK: - HomeCoordinator

/// Coordinator for the Home/Dashboard feature tab.
///
/// Responsibilities:
/// - Manages navigation within Home feature (dashboard, notifications)
/// - Owns HomeViewFactory for view construction
/// - Handles deep links to home-related screens
/// - Delegates cross-feature navigation to parent AppCoordinator
///
/// Navigation Stack:
/// - Root: Dashboard
/// - Can push: Notifications, Notification Detail
///
/// iOS 15 Pattern:
/// - Uses NavigationView with hidden NavigationLinks
/// - Recursive nestedLinks pattern for unlimited depth
/// - Binding synchronization for back button handling
final class HomeCoordinator: ObservableObject {

    // MARK: - Published State

    /// Navigation stack for programmatic navigation. Holds NavigationItem wrappers.
    @Published var navigationStack: [NavigationItem] = []

    /// Modal sheet presentation. Used for quick actions or secondary flows.
    @Published var presentedSheet: NavigationItem?

    /// Full-screen modal presentation. Used for immersive flows.
    @Published var presentedFullScreen: NavigationItem?

    // MARK: - Parent Reference

    /// Weak reference to AppCoordinator to prevent retain cycle.
    /// Used for cross-feature navigation (e.g., navigate to accounts from dashboard).
    private weak var parent: AppCoordinator?

    /// Child coordinator storage (optional pattern, not heavily used in this implementation).
    var childCoordinators: [String: AnyObject] = [:]

    // MARK: - Dependencies

    /// Dependency container providing service access.
    private let dependencyContainer: DependencyContainer

    /// View factory for creating Home feature views with ViewModels.
    private let viewFactory: HomeViewFactory

    // MARK: - Initialization

    /// Creates HomeCoordinator with parent and dependencies.
    ///
    /// - Parameters:
    ///   - parent: AppCoordinator reference (weak)
    ///   - dependencyContainer: Service container
    init(parent: AppCoordinator, dependencyContainer: DependencyContainer) {
        self.parent = parent
        self.dependencyContainer = dependencyContainer
        self.viewFactory = HomeViewFactory(dependencyContainer: dependencyContainer)
    }

    // MARK: - Navigation Methods

    /// Pushes a route onto the navigation stack.
    ///
    /// - Parameter route: The HomeRoute to navigate to
    func push(_ route: HomeRoute) {
        navigationStack.append(NavigationItem(route))
    }

    /// Pops the top route from the navigation stack.
    /// Defensive: does nothing if stack is empty.
    func pop() {
        guard !navigationStack.isEmpty else { return }
        navigationStack.removeLast()
    }

    /// Clears the entire navigation stack, returning to root (dashboard).
    func popToRoot() {
        navigationStack.removeAll()
    }

    /// Presents a route modally (sheet or full-screen).
    ///
    /// - Parameters:
    ///   - route: The HomeRoute to present
    ///   - fullScreen: If true, uses fullScreenCover; otherwise uses sheet
    func present(_ route: HomeRoute, fullScreen: Bool = false) {
        let item = NavigationItem(route)
        if fullScreen {
            presentedFullScreen = item
        } else {
            presentedSheet = item
        }
    }

    /// Dismisses the currently presented modal (sheet or full-screen).
    func dismiss() {
        presentedSheet = nil
        presentedFullScreen = nil
    }

    // MARK: - Cross-Feature Navigation (AC: #15 - Story 6.1)

    /// Navigates to account detail on Accounts tab.
    /// - Parameter accountId: The account ID to show details for
    func navigateToAccountDetail(accountId: String) {
        parent?.switchTab(.accounts)
        parent?.accountsCoordinator.push(.detail(accountId: accountId))
    }

    /// Navigates to transaction detail on Accounts tab.
    /// - Parameter transactionId: The transaction ID to show details for
    func navigateToTransactionDetail(transactionId: String) {
        parent?.switchTab(.accounts)
        parent?.accountsCoordinator.push(.transactionDetail(transactionId: transactionId))
    }

    /// Navigates to Transfer tab.
    func navigateToTransfer() {
        parent?.switchTab(.transfer)
    }

    /// Navigates to Cards tab.
    func navigateToCards() {
        parent?.switchTab(.cards)
    }

    /// Navigates to More tab.
    func navigateToMore() {
        parent?.switchTab(.more)
    }

    /// Navigates to security settings on More tab. (AC13 - Story 6.2)
    /// Used by notifications when security alert is tapped.
    func navigateToSecuritySettings() {
        parent?.switchTab(.more)
        parent?.moreCoordinator.push(.security)
    }

    // MARK: - Deep Link Handling

    /// Handles deep links to Home feature screens.
    ///
    /// Pattern:
    /// 1. Always popToRoot() first to clear existing stack
    /// 2. Build navigation stack by pushing routes in order
    ///
    /// Examples:
    /// - .dashboard → Already at root, do nothing
    /// - .notifications → Push notifications
    /// - .notificationDetail(id) → Push notifications, then notification detail
    ///
    /// - Parameter route: The HomeRoute from deep link
    func handle(deepLink route: HomeRoute) {
        popToRoot()

        switch route {
        case .dashboard:
            // Already at root dashboard
            break

        case .notifications:
            push(.notifications)

        case .notificationDetail(let notificationId):
            // Navigate through notifications to detail
            push(.notifications)
            push(.notificationDetail(notificationId: notificationId))
        }
    }

    // MARK: - View Building

    /// Builds the view for a given route using ViewFactory.
    ///
    /// Called by HomeCoordinatorView for each route in navigation stack and modals.
    ///
    /// - Parameter route: The HomeRoute to build a view for
    /// - Returns: The SwiftUI view for the route
    @ViewBuilder
    func build(_ route: HomeRoute) -> some View {
        switch route {
        case .dashboard:
            viewFactory.makeDashboardView(coordinator: self)

        case .notifications:
            viewFactory.makeNotificationsView(coordinator: self)

        case .notificationDetail(let notificationId):
            viewFactory.makeNotificationDetailView(notificationId: notificationId, coordinator: self)
        }
    }

    /// Returns the root CoordinatorView for this feature.
    ///
    /// Called by MainTabView to render the Home tab.
    ///
    /// - Returns: HomeCoordinatorView with this coordinator
    @ViewBuilder
    func rootView() -> some View {
        HomeCoordinatorView(coordinator: self)
    }
}

// MARK: - HomeCoordinatorView

/// SwiftUI view wrapper for HomeCoordinator implementing iOS 15 recursive navigation pattern.
///
/// Pattern Details:
/// - NavigationView with .stack style (required for iOS 15)
/// - Root view: coordinator.build(.dashboard)
/// - Hidden NavigationLinks in background for programmatic navigation
/// - Recursive nestedLinks function enables unlimited depth
/// - Binding synchronization handles back button pops
///
/// Memory:
/// - @ObservedObject (not @StateObject) - coordinator created by AppCoordinator
struct HomeCoordinatorView: View {
    @ObservedObject var coordinator: HomeCoordinator

    var body: some View {
        NavigationView {
            coordinator.build(.dashboard)
                .background(navigationLinks)
        }
        .navigationViewStyle(.stack)
        .sheet(item: $coordinator.presentedSheet) { item in
            if let route = item.route.base as? HomeRoute {
                NavigationView {
                    coordinator.build(route)
                }
            }
        }
        .fullScreenCover(item: $coordinator.presentedFullScreen) { item in
            if let route = item.route.base as? HomeRoute {
                NavigationView {
                    coordinator.build(route)
                }
            }
        }
    }

    // MARK: - Navigation Links

    /// Hidden NavigationLinks for programmatic navigation.
    /// Creates links for each item in navigation stack.
    @ViewBuilder
    private var navigationLinks: some View {
        ForEach(Array(coordinator.navigationStack.enumerated()), id: \.element.id) { index, item in
            if let route = item.route.base as? HomeRoute {
                NavigationLink(
                    destination: coordinator.build(route)
                        .background(nestedLinks(from: index + 1)),
                    isActive: binding(for: index)
                ) {
                    EmptyView()
                }
                .hidden()
            }
        }
    }

    /// Recursive function creating nested NavigationLinks for deeper navigation levels.
    ///
    /// This recursion enables unlimited navigation depth on iOS 15.
    /// Each screen contains links for all subsequent screens in the stack.
    ///
    /// - Parameter index: The stack index to create links from
    /// - Returns: Nested NavigationLinks for remaining stack
    @ViewBuilder
    private func nestedLinks(from index: Int) -> AnyView {
        if index < coordinator.navigationStack.count,
           let route = coordinator.navigationStack[index].route.base as? HomeRoute {
            return AnyView(
                NavigationLink(
                    destination: coordinator.build(route)
                        .background(nestedLinks(from: index + 1)),
                    isActive: binding(for: index)
                ) {
                    EmptyView()
                }
                .hidden()
            )
        } else {
            return AnyView(EmptyView())
        }
    }

    /// Creates a two-way binding for NavigationLink isActive state.
    ///
    /// Synchronizes navigation stack with actual navigation:
    /// - get: Returns true if index is within current stack bounds
    /// - set: When user taps back button (isActive becomes false), truncates stack
    ///
    /// - Parameter index: The stack index for this link
    /// - Returns: Binding for NavigationLink isActive
    private func binding(for index: Int) -> Binding<Bool> {
        Binding(
            get: { index < coordinator.navigationStack.count },
            set: { isActive in
                if !isActive && index < coordinator.navigationStack.count {
                    // User tapped back - sync coordinator state
                    coordinator.navigationStack = Array(coordinator.navigationStack.prefix(index))
                }
            }
        )
    }
}
