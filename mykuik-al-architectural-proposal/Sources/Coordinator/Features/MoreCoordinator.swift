import Foundation
import SwiftUI
import Combine

// MARK: - MoreCoordinator

/// Coordinator for the More/Settings feature tab.
///
/// Responsibilities:
/// - Manages navigation within More feature (menu, profile, security, settings, support, about)
/// - Owns MoreViewFactory for view construction
/// - Handles deep links to settings-related screens
/// - Implements logout delegation to parent AppCoordinator
///
/// Navigation Stack:
/// - Root: More Menu
/// - Can push: Profile, Security Settings, Change Password, Change PIN, Notification Settings, Support, About
///
/// Special Responsibilities:
/// - logout() → Delegates to parent.logout() for app-wide logout coordination
///
/// iOS 15 Pattern:
/// - Uses NavigationView with hidden NavigationLinks
/// - Recursive nestedLinks pattern for unlimited depth
/// - Binding synchronization for back button handling
final class MoreCoordinator: ObservableObject {

    // MARK: - Published State

    /// Navigation stack for programmatic navigation. Holds NavigationItem wrappers.
    @Published var navigationStack: [NavigationItem] = []

    /// Modal sheet presentation. Used for quick actions or secondary flows.
    @Published var presentedSheet: NavigationItem?

    /// Full-screen modal presentation. Used for immersive flows.
    @Published var presentedFullScreen: NavigationItem?

    // MARK: - Parent Reference

    /// Weak reference to AppCoordinator to prevent retain cycle.
    /// CRITICAL: Used for logout delegation to coordinate app-wide logout.
    private weak var parent: AppCoordinator?

    /// Child coordinator storage (optional pattern, not heavily used in this implementation).
    var childCoordinators: [String: AnyObject] = [:]

    // MARK: - Dependencies

    /// Dependency container providing service access.
    private let dependencyContainer: DependencyContainer

    /// View factory for creating More feature views with ViewModels.
    private let viewFactory: MoreViewFactory

    // MARK: - Initialization

    /// Creates MoreCoordinator with parent and dependencies.
    ///
    /// - Parameters:
    ///   - parent: AppCoordinator reference (weak)
    ///   - dependencyContainer: Service container
    init(parent: AppCoordinator, dependencyContainer: DependencyContainer) {
        self.parent = parent
        self.dependencyContainer = dependencyContainer
        self.viewFactory = MoreViewFactory(dependencyContainer: dependencyContainer)
    }

    // MARK: - Navigation Methods

    /// Pushes a route onto the navigation stack.
    ///
    /// - Parameter route: The MoreRoute to navigate to
    func push(_ route: MoreRoute) {
        navigationStack.append(NavigationItem(route))
    }

    /// Pops the top route from the navigation stack.
    /// Defensive: does nothing if stack is empty.
    func pop() {
        guard !navigationStack.isEmpty else { return }
        navigationStack.removeLast()
    }

    /// Clears the entire navigation stack, returning to root (more menu).
    func popToRoot() {
        navigationStack.removeAll()
    }

    /// Presents a route modally (sheet or full-screen).
    ///
    /// - Parameters:
    ///   - route: The MoreRoute to present
    ///   - fullScreen: If true, uses fullScreenCover; otherwise uses sheet
    func present(_ route: MoreRoute, fullScreen: Bool = false) {
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

    // MARK: - Logout (Story 2.11 AC: #3)

    /// Requests logout by delegating to parent AppCoordinator.
    ///
    /// Parent-mediated pattern (Story 2.11 AC: #3):
    /// - MoreCoordinator doesn't directly call AuthService
    /// - Calls parent?.logout() which coordinates:
    ///   1. AuthService.logout() async call
    ///   2. Reset all feature coordinator navigation stacks
    ///   3. Dismiss any presented modals
    ///   4. Return to home tab
    ///   5. RootView observes isAuthenticated change and shows login
    ///
    /// Called by:
    /// - MoreMenuViewModel.logout() (user confirms logout from More menu)
    func requestLogout() {
        parent?.logout()
    }

    // MARK: - Deep Link Handling

    /// Handles deep links to More feature screens.
    ///
    /// Pattern:
    /// 1. Always popToRoot() first to clear existing stack
    /// 2. Build navigation stack by pushing routes in order
    ///
    /// Examples:
    /// - .menu → Already at root, do nothing
    /// - .profile → Push profile
    /// - .security → Push security settings
    /// - .changePassword → Push security, then change password
    /// - .changePIN → Push security, then change PIN
    /// - .notificationSettings → Push notification settings
    /// - .support → Push support
    /// - .about → Push about
    ///
    /// - Parameter route: The MoreRoute from deep link
    func handle(deepLink route: MoreRoute) {
        popToRoot()

        switch route {
        case .menu:
            // Already at root menu
            break

        case .profile:
            push(.profile)

        case .editProfile:
            push(.profile)
            push(.editProfile)

        case .security:
            push(.security)

        case .changePassword:
            // Navigate through security to change password
            push(.security)
            push(.changePassword)

        case .changePIN:
            // Navigate through security to change PIN
            push(.security)
            push(.changePIN)

        case .notificationSettings:
            push(.notificationSettings)

        case .support:
            push(.support)

        case .about:
            push(.about)
        }
    }

    // MARK: - View Building

    /// Builds the view for a given route using ViewFactory.
    ///
    /// Called by MoreCoordinatorView for each route in navigation stack and modals.
    ///
    /// - Parameter route: The MoreRoute to build a view for
    /// - Returns: The SwiftUI view for the route
    @ViewBuilder
    func build(_ route: MoreRoute) -> some View {
        switch route {
        case .menu:
            viewFactory.makeMoreMenuView(coordinator: self)

        case .profile:
            viewFactory.makeProfileView(coordinator: self)

        case .editProfile:
            viewFactory.makeEditProfileView(coordinator: self)

        case .security:
            viewFactory.makeSecuritySettingsView(coordinator: self)

        case .changePassword:
            viewFactory.makeChangePasswordView(coordinator: self)

        case .changePIN:
            viewFactory.makeChangePINView(coordinator: self)

        case .notificationSettings:
            viewFactory.makeNotificationSettingsView(coordinator: self)

        case .support:
            viewFactory.makeSupportView(coordinator: self)

        case .about:
            viewFactory.makeAboutView(coordinator: self)
        }
    }

    /// Returns the root CoordinatorView for this feature.
    ///
    /// Called by MainTabView to render the More tab.
    ///
    /// - Returns: MoreCoordinatorView with this coordinator
    @ViewBuilder
    func rootView() -> some View {
        MoreCoordinatorView(coordinator: self)
    }
}

// MARK: - MoreCoordinatorView

/// SwiftUI view wrapper for MoreCoordinator implementing iOS 15 recursive navigation pattern.
///
/// Pattern Details:
/// - NavigationView with .stack style (required for iOS 15)
/// - Root view: coordinator.build(.menu)
/// - Hidden NavigationLinks in background for programmatic navigation
/// - Recursive nestedLinks function enables unlimited depth
/// - Binding synchronization handles back button pops
///
/// Memory:
/// - @ObservedObject (not @StateObject) - coordinator created by AppCoordinator
struct MoreCoordinatorView: View {
    @ObservedObject var coordinator: MoreCoordinator

    var body: some View {
        NavigationView {
            coordinator.build(.menu)
                .background(navigationLinks)
        }
        .navigationViewStyle(.stack)
        .sheet(item: $coordinator.presentedSheet) { item in
            if let route = item.route.base as? MoreRoute {
                NavigationView {
                    coordinator.build(route)
                }
            }
        }
        .fullScreenCover(item: $coordinator.presentedFullScreen) { item in
            if let route = item.route.base as? MoreRoute {
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
           let route = firstItem.route.base as? MoreRoute {
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
           let route = coordinator.navigationStack[index].route.base as? MoreRoute {
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
