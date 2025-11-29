import Foundation
import SwiftUI
import Combine

// MARK: - TransferCoordinator

/// Coordinator for the Transfer feature tab.
///
/// Responsibilities:
/// - Manages navigation within Transfer feature (home, internal/external transfers, beneficiaries, confirmation, receipt)
/// - Owns TransferViewFactory for view construction
/// - Handles deep links to transfer-related screens
/// - Supports cross-feature entry point (from Accounts with pre-filled source account)
///
/// Navigation Stack:
/// - Root: Transfer Home
/// - Can push: Internal Transfer, External Transfer, Beneficiary List, Add Beneficiary, Confirmation, Receipt
///
/// Cross-Feature Integration:
/// - .internalTransferWithAccount(fromAccountId) → Used when navigating from Accounts tab
///
/// iOS 15 Pattern:
/// - Uses NavigationView with hidden NavigationLinks
/// - Recursive nestedLinks pattern for unlimited depth
/// - Binding synchronization for back button handling
final class TransferCoordinator: ObservableObject {

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

    /// Child coordinator storage (optional pattern, not heavily used in this implementation).
    var childCoordinators: [String: AnyObject] = [:]

    // MARK: - Dependencies

    /// Dependency container providing service access.
    private let dependencyContainer: DependencyContainer

    /// View factory for creating Transfer feature views with ViewModels.
    private let viewFactory: TransferViewFactory

    // MARK: - Initialization

    /// Creates TransferCoordinator with parent and dependencies.
    ///
    /// - Parameters:
    ///   - parent: AppCoordinator reference (weak)
    ///   - dependencyContainer: Service container
    init(parent: AppCoordinator, dependencyContainer: DependencyContainer) {
        self.parent = parent
        self.dependencyContainer = dependencyContainer
        self.viewFactory = TransferViewFactory(dependencyContainer: dependencyContainer)
    }

    // MARK: - Navigation Methods

    /// Pushes a route onto the navigation stack.
    ///
    /// - Parameter route: The TransferRoute to navigate to
    func push(_ route: TransferRoute) {
        navigationStack.append(NavigationItem(route))
    }

    /// Pops the top route from the navigation stack.
    /// Defensive: does nothing if stack is empty.
    func pop() {
        guard !navigationStack.isEmpty else { return }
        navigationStack.removeLast()
    }

    /// Clears the entire navigation stack, returning to root (transfer home).
    func popToRoot() {
        navigationStack.removeAll()
    }

    /// Presents a route modally (sheet or full-screen).
    ///
    /// - Parameters:
    ///   - route: The TransferRoute to present
    ///   - fullScreen: If true, uses fullScreenCover; otherwise uses sheet
    func present(_ route: TransferRoute, fullScreen: Bool = false) {
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

    // MARK: - Deep Link Handling

    /// Handles deep links to Transfer feature screens.
    ///
    /// Pattern:
    /// 1. Always popToRoot() first to clear existing stack
    /// 2. Build navigation stack by pushing routes in order
    ///
    /// Examples:
    /// - .home → Already at root, do nothing
    /// - .internalTransfer → Push internal transfer
    /// - .internalTransferWithAccount(fromAccountId) → Push internal transfer with pre-filled account
    /// - .externalTransfer → Push external transfer
    /// - .beneficiaryList → Push beneficiary list
    /// - .addBeneficiary → Push add beneficiary
    /// - .confirmation(transferId) → Push confirmation (may navigate through transfer flow first)
    /// - .receipt(transferId) → Push receipt directly
    ///
    /// - Parameter route: The TransferRoute from deep link
    func handle(deepLink route: TransferRoute) {
        popToRoot()

        switch route {
        case .home:
            // Already at root transfer home
            break

        case .internalTransfer:
            push(.internalTransfer)

        case .internalTransferWithAccount(let fromAccountId):
            // Cross-feature entry point from Accounts
            push(.internalTransferWithAccount(fromAccountId: fromAccountId))

        case .externalTransfer:
            push(.externalTransfer)

        case .beneficiaryList:
            push(.beneficiaryList)

        case .addBeneficiary:
            // Navigate through beneficiary list to add
            push(.beneficiaryList)
            push(.addBeneficiary)

        case .confirmation(let transferId):
            // Direct to confirmation (ideally would navigate through transfer flow)
            push(.confirmation(transferId: transferId))

        case .receipt(let transferId):
            // Direct to receipt
            push(.receipt(transferId: transferId))
        }
    }

    // MARK: - View Building

    /// Builds the view for a given route using ViewFactory.
    ///
    /// Called by TransferCoordinatorView for each route in navigation stack and modals.
    ///
    /// - Parameter route: The TransferRoute to build a view for
    /// - Returns: The SwiftUI view for the route
    @ViewBuilder
    func build(_ route: TransferRoute) -> some View {
        switch route {
        case .home:
            viewFactory.makeTransferHomeView(coordinator: self)

        case .internalTransfer:
            viewFactory.makeInternalTransferView(coordinator: self)

        case .internalTransferWithAccount(let fromAccountId):
            viewFactory.makeInternalTransferWithAccountView(fromAccountId: fromAccountId, coordinator: self)

        case .externalTransfer:
            viewFactory.makeExternalTransferView(coordinator: self)

        case .beneficiaryList:
            viewFactory.makeBeneficiaryListView(coordinator: self)

        case .addBeneficiary:
            viewFactory.makeAddBeneficiaryView(coordinator: self)

        case .confirmation(let transferId):
            viewFactory.makeTransferConfirmationView(transferId: transferId, coordinator: self)

        case .receipt(let transferId):
            viewFactory.makeTransferReceiptView(transferId: transferId, coordinator: self)
        }
    }

    /// Returns the root CoordinatorView for this feature.
    ///
    /// Called by MainTabView to render the Transfer tab.
    ///
    /// - Returns: TransferCoordinatorView with this coordinator
    @ViewBuilder
    func rootView() -> some View {
        TransferCoordinatorView(coordinator: self)
    }
}

// MARK: - TransferCoordinatorView

/// SwiftUI view wrapper for TransferCoordinator implementing iOS 15 recursive navigation pattern.
///
/// Pattern Details:
/// - NavigationView with .stack style (required for iOS 15)
/// - Root view: coordinator.build(.home)
/// - Hidden NavigationLinks in background for programmatic navigation
/// - Recursive nestedLinks function enables unlimited depth
/// - Binding synchronization handles back button pops
///
/// Memory:
/// - @ObservedObject (not @StateObject) - coordinator created by AppCoordinator
struct TransferCoordinatorView: View {
    @ObservedObject var coordinator: TransferCoordinator

    var body: some View {
        NavigationView {
            coordinator.build(.home)
                .background(navigationLinks)
        }
        .navigationViewStyle(.stack)
        .sheet(item: $coordinator.presentedSheet) { item in
            if let route = item.route.base as? TransferRoute {
                NavigationView {
                    coordinator.build(route)
                }
            }
        }
        .fullScreenCover(item: $coordinator.presentedFullScreen) { item in
            if let route = item.route.base as? TransferRoute {
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
            if let route = item.route.base as? TransferRoute {
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
           let route = coordinator.navigationStack[index].route.base as? TransferRoute {
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
