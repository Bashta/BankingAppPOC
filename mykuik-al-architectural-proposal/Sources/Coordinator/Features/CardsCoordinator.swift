import Foundation
import SwiftUI
import Combine

// MARK: - CardsCoordinator

/// Coordinator for the Cards feature tab.
///
/// Responsibilities:
/// - Manages navigation within Cards feature (list, detail, settings, limits, block, activate, PIN change)
/// - Owns CardsViewFactory for view construction
/// - Handles deep links to card-related screens
/// - Delegates cross-feature navigation to parent AppCoordinator if needed
///
/// Navigation Stack:
/// - Root: Cards List
/// - Can push: Card Detail, Card Settings, Card Limits, Block Card, Activate Card, PIN Change
///
/// iOS 15 Pattern:
/// - Uses NavigationView with hidden NavigationLinks
/// - Recursive nestedLinks pattern for unlimited depth
/// - Binding synchronization for back button handling
final class CardsCoordinator: ObservableObject {

    // MARK: - Published State

    /// Navigation stack for programmatic navigation. Holds NavigationItem wrappers.
    @Published var navigationStack: [NavigationItem] = []

    /// Modal sheet presentation. Used for quick actions or secondary flows.
    @Published var presentedSheet: NavigationItem?

    /// Full-screen modal presentation. Used for immersive flows.
    @Published var presentedFullScreen: NavigationItem?

    // MARK: - Parent Reference

    /// Weak reference to AppCoordinator to prevent retain cycle.
    /// Used for cross-feature navigation if needed.
    private weak var parent: AppCoordinator?

    // MARK: - Dependencies

    /// View factory for creating Cards feature views with ViewModels.
    private let viewFactory: CardsViewFactory

    // MARK: - Initialization

    /// Creates CardsCoordinator with parent and dependencies.
    ///
    /// - Parameters:
    ///   - parent: AppCoordinator reference (weak)
    ///   - dependencyContainer: Service container
    init(parent: AppCoordinator, dependencyContainer: DependencyContainer) {
        self.parent = parent
        self.viewFactory = CardsViewFactory(dependencyContainer: dependencyContainer)
    }

    // MARK: - Navigation Methods

    /// Pushes a route onto the navigation stack.
    ///
    /// - Parameter route: The CardsRoute to navigate to
    func push(_ route: CardsRoute) {
        navigationStack.append(NavigationItem(route))
    }

    /// Pops the top route from the navigation stack.
    /// Defensive: does nothing if stack is empty.
    func pop() {
        guard !navigationStack.isEmpty else { return }
        navigationStack.removeLast()
    }

    /// Clears the entire navigation stack, returning to root (cards list).
    func popToRoot() {
        navigationStack.removeAll()
    }

    /// Dismisses the currently presented modal (sheet or full-screen).
    func dismiss() {
        presentedSheet = nil
        presentedFullScreen = nil
    }

    // MARK: - Cross-Feature Navigation

    /// Navigates to transaction history for a linked account.
    /// Used by CardDetailView to show card-related transactions.
    ///
    /// - Parameter accountId: The account ID to show transactions for
    func navigateToAccountTransactions(accountId: String) {
        parent?.switchTab(.accounts)
        parent?.accountsCoordinator.push(.transactions(accountId: accountId))
    }

    /// Navigates to support section in More tab.
    /// Used by BlockCardView when card cannot be unblocked and user needs support.
    func navigateToSupport() {
        parent?.switchTab(.more)
        parent?.moreCoordinator.push(.support)
    }

    // MARK: - Deep Link Handling

    /// Handles deep links to Cards feature screens.
    ///
    /// Pattern:
    /// 1. Always popToRoot() first to clear existing stack
    /// 2. Build navigation stack by pushing routes in order (least specific to most specific)
    ///
    /// Examples:
    /// - .list → Already at root, do nothing
    /// - .detail(cardId) → Push detail
    /// - .settings(cardId) → Push detail, then settings
    /// - .limits(cardId) → Push detail, then limits
    /// - .block(cardId, status, reason) → Push detail, then block
    /// - .activate(cardId) → Push detail, then activate
    /// - .pinChange(cardId) → Push detail, then PIN change
    ///
    /// - Parameter route: The CardsRoute from deep link
    func handle(deepLink route: CardsRoute) {
        popToRoot()

        switch route {
        case .list:
            // Already at root list
            break

        case .detail(let cardId):
            push(.detail(cardId: cardId))

        case .settings(let cardId):
            // Navigate through detail to settings
            push(.detail(cardId: cardId))
            push(.settings(cardId: cardId))

        case .limits(let cardId):
            // Navigate through detail to limits
            push(.detail(cardId: cardId))
            push(.limits(cardId: cardId))

        case .block(let cardId, let currentStatus, let blockReason):
            // Navigate through detail to block
            push(.detail(cardId: cardId))
            push(.block(cardId: cardId, currentStatus: currentStatus, blockReason: blockReason))

        case .activate(let cardId):
            // Navigate through detail to activate
            push(.detail(cardId: cardId))
            push(.activate(cardId: cardId))

        case .pinChange(let cardId):
            // Navigate through detail to PIN change
            push(.detail(cardId: cardId))
            push(.pinChange(cardId: cardId))
        }
    }

    // MARK: - View Building

    /// Builds the view for a given route using ViewFactory.
    ///
    /// Called by CardsCoordinatorView for each route in navigation stack and modals.
    ///
    /// - Parameter route: The CardsRoute to build a view for
    /// - Returns: The SwiftUI view for the route
    @ViewBuilder
    func build(_ route: CardsRoute) -> some View {
        switch route {
        case .list:
            viewFactory.makeCardsListView(coordinator: self)

        case .detail(let cardId):
            viewFactory.makeCardDetailView(cardId: cardId, coordinator: self)

        case .settings(let cardId):
            viewFactory.makeCardSettingsView(cardId: cardId, coordinator: self)

        case .limits(let cardId):
            viewFactory.makeCardLimitsView(cardId: cardId, coordinator: self)

        case .block(let cardId, let currentStatus, let blockReason):
            viewFactory.makeBlockCardView(cardId: cardId, currentStatus: currentStatus, blockReason: blockReason, coordinator: self)

        case .activate(let cardId):
            viewFactory.makeActivateCardView(cardId: cardId, coordinator: self)

        case .pinChange(let cardId):
            viewFactory.makeChangePINView(cardId: cardId, coordinator: self)
        }
    }

    /// Returns the root CoordinatorView for this feature.
    ///
    /// Called by MainTabView to render the Cards tab.
    ///
    /// - Returns: CardsCoordinatorView with this coordinator
    @ViewBuilder
    func rootView() -> some View {
        CardsCoordinatorView(coordinator: self)
    }
}

// MARK: - CardsCoordinatorView

/// SwiftUI view wrapper for CardsCoordinator implementing iOS 15 recursive navigation pattern.
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
struct CardsCoordinatorView: View {
    @ObservedObject var coordinator: CardsCoordinator

    var body: some View {
        NavigationView {
            coordinator.build(.list)
                .background(navigationLinks)
        }
        .navigationViewStyle(.stack)
        .sheet(item: $coordinator.presentedSheet) { item in
            if let route = item.route.base as? CardsRoute {
                NavigationView {
                    coordinator.build(route)
                }
            }
        }
        .fullScreenCover(item: $coordinator.presentedFullScreen) { item in
            if let route = item.route.base as? CardsRoute {
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
           let route = firstItem.route.base as? CardsRoute {
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
    @ViewBuilder
    private func nestedLinks(from index: Int) -> AnyView {
        if index < coordinator.navigationStack.count,
           let route = coordinator.navigationStack[index].route.base as? CardsRoute {
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
