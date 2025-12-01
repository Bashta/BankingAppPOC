import Foundation
import SwiftUI
import Combine

// MARK: - AccountsCoordinator

/// Coordinator for the Accounts feature tab.
///
/// Responsibilities:
/// - Manages navigation within Accounts feature (list, detail, transactions, statements)
/// - Owns AccountsViewFactory for view construction
/// - Handles deep links to account-related screens
/// - Implements cross-feature navigation to Transfer (via parent)
///
/// Navigation Stack:
/// - Root: Accounts List
/// - Can push: Account Detail, Transaction History, Transaction Detail, Statement, Statement Download
///
/// Cross-Feature Navigation:
/// - navigateToTransfer(fromAccountId:) → switches to Transfer tab with account pre-filled
///
/// iOS 15 Pattern:
/// - Uses NavigationView with hidden NavigationLinks
/// - Recursive nestedLinks pattern for unlimited depth
/// - Binding synchronization for back button handling
final class AccountsCoordinator: ObservableObject {

    // MARK: - Published State

    /// Navigation stack for programmatic navigation. Holds NavigationItem wrappers.
    @Published var navigationStack: [NavigationItem] = []

    /// Modal sheet presentation. Used for quick actions or secondary flows.
    @Published var presentedSheet: NavigationItem?

    /// Full-screen modal presentation. Used for immersive flows.
    @Published var presentedFullScreen: NavigationItem?

    // MARK: - Parent Reference

    /// Weak reference to AppCoordinator to prevent retain cycle.
    /// Used for cross-feature navigation (e.g., initiate transfer from account detail).
    private weak var parent: AppCoordinator?

    // MARK: - Dependencies

    /// View factory for creating Accounts feature views with ViewModels.
    private let viewFactory: AccountsViewFactory

    // MARK: - Initialization

    /// Creates AccountsCoordinator with parent and dependencies.
    ///
    /// - Parameters:
    ///   - parent: AppCoordinator reference (weak)
    ///   - dependencyContainer: Service container
    init(parent: AppCoordinator, dependencyContainer: DependencyContainer) {
        self.parent = parent
        self.viewFactory = AccountsViewFactory(dependencyContainer: dependencyContainer)
    }

    // MARK: - Navigation Methods

    /// Pushes a route onto the navigation stack.
    ///
    /// - Parameter route: The AccountsRoute to navigate to
    func push(_ route: AccountsRoute) {
        navigationStack.append(NavigationItem(route))
    }

    /// Clears the entire navigation stack, returning to root (accounts list).
    func popToRoot() {
        navigationStack.removeAll()
    }

    /// Dismisses the currently presented modal (sheet or full-screen).
    func dismiss() {
        presentedSheet = nil
        presentedFullScreen = nil
    }

    // MARK: - Cross-Feature Navigation

    /// Navigates to Transfer tab with account pre-filled for internal transfer.
    ///
    /// Pattern: Parent-mediated cross-feature navigation
    /// 1. Call parent?.switchTab(.transfer) to change tabs
    /// 2. Call parent?.transferCoordinator.push(...) to navigate within Transfer feature
    ///
    /// Use case: User taps "Transfer" button on account detail screen
    ///
    /// - Parameter fromAccountId: The account ID to use as source account
    func navigateToTransfer(fromAccountId: String) {
        parent?.switchTab(.transfer)
        parent?.transferCoordinator.push(.internalTransferWithAccount(fromAccountId: fromAccountId))
    }

    // MARK: - Deep Link Handling

    /// Handles deep links to Accounts feature screens.
    ///
    /// Pattern:
    /// 1. Always popToRoot() first to clear existing stack
    /// 2. Build navigation stack by pushing routes in order (least specific to most specific)
    ///
    /// Examples:
    /// - .list → Already at root, do nothing
    /// - .detail(accountId) → Push detail
    /// - .transactions(accountId) → Push detail, then transactions
    /// - .transactionDetail(transactionId) → Push transaction detail (may not have full context)
    /// - .statement(accountId) → Push detail, then statement
    /// - .statementDownload(accountId, month, year) → Push detail, then statement download
    ///
    /// - Parameter route: The AccountsRoute from deep link
    func handle(deepLink route: AccountsRoute) {
        popToRoot()

        switch route {
        case .list:
            // Already at root list
            break

        case .detail(let accountId):
            push(.detail(accountId: accountId))

        case .transactions(let accountId):
            // Navigate through detail to transactions
            push(.detail(accountId: accountId))
            push(.transactions(accountId: accountId))

        case .transactionDetail(let transactionId):
            // Direct transaction detail (may lack account context)
            // Ideally would fetch transaction to get accountId, but for POC just push directly
            push(.transactionDetail(transactionId: transactionId))

        case .statement(let accountId):
            // Navigate through detail to statement
            push(.detail(accountId: accountId))
            push(.statement(accountId: accountId))

        case .statementDownload(let accountId, let month, let year):
            // Navigate through detail to statement download
            push(.detail(accountId: accountId))
            push(.statementDownload(accountId: accountId, month: month, year: year))
        }
    }

    // MARK: - View Building

    /// Builds the view for a given route using ViewFactory.
    ///
    /// Called by AccountsCoordinatorView for each route in navigation stack and modals.
    ///
    /// - Parameter route: The AccountsRoute to build a view for
    /// - Returns: The SwiftUI view for the route
    @ViewBuilder
    func build(_ route: AccountsRoute) -> some View {
        switch route {
        case .list:
            viewFactory.makeAccountsListView(coordinator: self)

        case .detail(let accountId):
            viewFactory.makeAccountDetailView(accountId: accountId, coordinator: self)

        case .transactions(let accountId):
            viewFactory.makeTransactionHistoryView(accountId: accountId, coordinator: self)

        case .transactionDetail(let transactionId):
            viewFactory.makeTransactionDetailView(transactionId: transactionId, coordinator: self)

        case .statement(let accountId):
            viewFactory.makeStatementView(accountId: accountId, coordinator: self)

        case .statementDownload(let accountId, let month, let year):
            viewFactory.makeStatementDownloadView(accountId: accountId, month: month, year: year, coordinator: self)
        }
    }

    /// Returns the root CoordinatorView for this feature.
    ///
    /// Called by MainTabView to render the Accounts tab.
    ///
    /// - Returns: AccountsCoordinatorView with this coordinator
    @ViewBuilder
    func rootView() -> some View {
        AccountsCoordinatorView(coordinator: self)
    }
}

// MARK: - AccountsCoordinatorView

/// SwiftUI view wrapper for AccountsCoordinator implementing iOS 15 recursive navigation pattern.
///
/// Pattern Details:
/// - NavigationView with .stack style (required for iOS 15)
/// - Root view: coordinator.build(.list)
/// - Hidden NavigationLinks in background for programmatic navigation
/// - Recursive nestedLinks function enables unlimited depth
/// - Binding synchronization handles back button pops
///
/// Memory:
/// - @ObservedObject (not @StateObject) - coordinator created by AppCoordinator
struct AccountsCoordinatorView: View {
    @ObservedObject var coordinator: AccountsCoordinator

    var body: some View {
        NavigationView {
            coordinator.build(.list)
                .background(navigationLinks)
        }
        .navigationViewStyle(.stack)
        .sheet(item: $coordinator.presentedSheet) { item in
            if let route = item.route.base as? AccountsRoute {
                NavigationView {
                    coordinator.build(route)
                }
            }
        }
        .fullScreenCover(item: $coordinator.presentedFullScreen) { item in
            if let route = item.route.base as? AccountsRoute {
                NavigationView {
                    coordinator.build(route)
                }
            }
        }
    }

    // MARK: - Navigation Links

    /// Hidden NavigationLink for programmatic navigation.
    /// Only creates ONE link at root - recursion handles deeper levels.
    @ViewBuilder
    private var navigationLinks: some View {
        // Only create link for first item - nestedLinks handles the rest
        if let firstItem = coordinator.navigationStack.first,
           let route = firstItem.route.base as? AccountsRoute {
            NavigationLink(
                destination: coordinator.build(route)
                    .background(nestedLinks(from: 1)),
                isActive: Binding(
                    get: { !coordinator.navigationStack.isEmpty },
                    set: { isActive in
                        if !isActive {
                            coordinator.navigationStack.removeAll()
                        }
                    }
                )
            ) {
                EmptyView()
            }
            .hidden()
        }
    }

    /// Recursive function creating nested NavigationLinks for deeper navigation levels.
    ///
    /// This recursion enables unlimited navigation depth on iOS 15.
    /// Each screen contains links for all subsequent screens in the stack.
    ///
    /// - Parameter index: The stack index to create links from
    /// - Returns: Nested NavigationLinks for remaining stack
    private func nestedLinks(from index: Int) -> AnyView {
        if index < coordinator.navigationStack.count,
           let route = coordinator.navigationStack[index].route.base as? AccountsRoute {
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
