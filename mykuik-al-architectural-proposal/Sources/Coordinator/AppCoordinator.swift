import Foundation
import SwiftUI
import Combine
import OSLog

// MARK: - AppTab Enum

/// Represents the main tabs in the banking app's TabView.
/// Each tab corresponds to a feature coordinator and its navigation hierarchy.
enum AppTab: String, CaseIterable {
    case home
    case accounts
    case transfer
    case cards
    case more
}

// MARK: - AppCoordinator

/// Root coordinator managing the entire app's navigation hierarchy, tab state, and authentication.
///
/// Responsibilities:
/// - Creates and owns all 6 feature child coordinators (Home, Accounts, Transfer, Cards, More, Auth)
/// - Manages TabView selected tab state
/// - Observes authentication state from AuthService
/// - Processes deep links (with authentication gate)
/// - Coordinates cross-feature navigation
/// - Handles logout and session expiration
///
/// Architecture Pattern:
/// - AppCoordinator holds strong references to child coordinators (owns their lifecycle)
/// - Child coordinators receive weak parent reference (prevents retain cycles)
/// - Uses Combine to observe AuthService.isAuthenticatedPublisher
/// - Stores pending deep links when user is not authenticated
///
/// Memory Management:
/// - Strong: AppCoordinator → Child Coordinators
/// - Weak: Child Coordinators → AppCoordinator (parent property)
/// - Weak: Combine sink closure uses [weak self]
final class AppCoordinator: ObservableObject {

    // MARK: - Published State

    /// Authentication state observed from AuthService. Drives RootView conditional rendering.
    @Published var isAuthenticated = false

    /// Currently selected tab in MainTabView. Changed via switchTab() or deep links.
    @Published var selectedTab: AppTab = .home

    /// Presented sheet modal. Used for cross-feature modals or quick actions.
    @Published var presentedSheet: NavigationItem?

    /// Presented full-screen cover. Used for auth flows (login, session expired).
    @Published var presentedFullScreen: NavigationItem?

    // MARK: - Child Coordinators
    //
    // All child coordinators are @Published private(set) for SwiftUI observation.
    // Set in setupChildCoordinators(), called from init.
    // Using implicitly unwrapped optionals since they're always set before use.

    @Published private(set) var homeCoordinator: HomeCoordinator!
    @Published private(set) var accountsCoordinator: AccountsCoordinator!
    @Published private(set) var transferCoordinator: TransferCoordinator!
    @Published private(set) var cardsCoordinator: CardsCoordinator!
    @Published private(set) var moreCoordinator: MoreCoordinator!
    @Published private(set) var authCoordinator: AuthCoordinator!

    /// Child coordinator storage for dynamic coordinator management (optional pattern).
    /// Not heavily used in this implementation but available for advanced scenarios.
    var childCoordinators: [String: AnyObject] = [:]

    // MARK: - Dependencies

    /// Dependency container providing all services to child coordinators.
    private let dependencyContainer: DependencyContainer

    /// Combine subscriptions storage. Observes AuthService.isAuthenticatedPublisher.
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Deep Linking

    /// Stores deep link URL received while user is not authenticated.
    /// Processed after successful login in processPendingDeepLink().
    private var pendingDeepLink: URL?

    // MARK: - Initialization

    /// Creates AppCoordinator with dependency container.
    ///
    /// Flow:
    /// 1. Store dependency container reference
    /// 2. Setup all 6 child coordinators (setupChildCoordinators)
    /// 3. Observe auth state from AuthService (observeAuthState)
    ///
    /// - Parameter dependencyContainer: Provides all service instances
    init(dependencyContainer: DependencyContainer) {
        self.dependencyContainer = dependencyContainer
        setupChildCoordinators()
        observeAuthState()
    }

    // MARK: - Setup

    /// Creates all 6 child coordinators with weak parent reference and dependency container.
    ///
    /// Each coordinator:
    /// - Receives weak self reference as parent (prevents retain cycle)
    /// - Receives strong dependencyContainer reference (for service access)
    /// - Creates own ViewFactory internally for view construction
    ///
    /// Note: Child coordinators will cause compilation errors until Story 1.4 implements them.
    /// This is expected and documented in AC.
    private func setupChildCoordinators() {
        homeCoordinator = HomeCoordinator(parent: self, dependencyContainer: dependencyContainer)
        accountsCoordinator = AccountsCoordinator(parent: self, dependencyContainer: dependencyContainer)
        transferCoordinator = TransferCoordinator(parent: self, dependencyContainer: dependencyContainer)
        cardsCoordinator = CardsCoordinator(parent: self, dependencyContainer: dependencyContainer)
        moreCoordinator = MoreCoordinator(parent: self, dependencyContainer: dependencyContainer)
        authCoordinator = AuthCoordinator(parent: self, dependencyContainer: dependencyContainer)
    }

    /// Observes AuthService authentication state via Combine publisher.
    ///
    /// Flow:
    /// 1. Subscribe to dependencyContainer.authService.isAuthenticatedPublisher
    /// 2. Ensure updates on main thread with .receive(on: DispatchQueue.main)
    /// 3. Sink with [weak self] to prevent retain cycle
    /// 4. Update isAuthenticated property (drives RootView rendering)
    /// 5. If authenticated becomes true, process pending deep link
    /// 6. Store subscription in cancellables set
    private func observeAuthState() {
        dependencyContainer.authService.isAuthenticatedPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isAuthenticated in
                self?.isAuthenticated = isAuthenticated
                if isAuthenticated {
                    self?.processPendingDeepLink()
                }
            }
            .store(in: &cancellables)
    }

    // MARK: - Tab Management

    /// Switches to the specified tab.
    ///
    /// Called by:
    /// - Child coordinators for cross-feature navigation (parent?.switchTab(.transfer))
    /// - Deep link processing (handle(route:) switches tab before delegating)
    /// - MainTabView user tap (two-way binding)
    ///
    /// - Parameter tab: The tab to activate
    func switchTab(_ tab: AppTab) {
        selectedTab = tab
    }

    // MARK: - Deep Link Handling

    /// Entry point for all deep links. Checks authentication before processing.
    ///
    /// Authentication Gate Pattern:
    /// - If NOT authenticated: Store in pendingDeepLink, show login (RootView observes isAuthenticated)
    /// - If authenticated: Process immediately
    ///
    /// Flow:
    /// 1. BankingApp.onOpenURL receives URL
    /// 2. Calls appCoordinator.handle(deepLink: url)
    /// 3. This method checks isAuthenticated
    /// 4. Either stores or processes
    ///
    /// - Parameter url: The deep link URL (e.g., bankapp://accounts/ACC123)
    func handle(deepLink url: URL) {
        guard isAuthenticated else {
            // User not logged in - store for later
            pendingDeepLink = url
            // Login screen shown by RootView observing isAuthenticated
            return
        }

        // User logged in - process now
        processDeepLink(url)
    }

    /// Processes a deep link URL by parsing and routing.
    ///
    /// Flow:
    /// 1. Call DeepLinkParser.parse(url)
    /// 2. Switch on Result<AppRoute, DeepLinkError>
    /// 3. Success: Call handle(route:) with parsed route
    /// 4. Failure: Log error for debugging
    ///
    /// - Parameter url: The deep link URL to process
    private func processDeepLink(_ url: URL) {
        let result = DeepLinkParser.parse(url)

        switch result {
        case .success(let route):
            handle(route: route)
        case .failure(let error):
            Logger.deepLink.error("Deep link parsing error: \(error)")
        }
    }

    /// Processes the pending deep link if one exists.
    ///
    /// Called from:
    /// - observeAuthState() sink when isAuthenticated becomes true
    ///
    /// Flow:
    /// 1. Check if pendingDeepLink exists
    /// 2. Clear pendingDeepLink (avoid re-processing)
    /// 3. Process the URL
    private func processPendingDeepLink() {
        guard let url = pendingDeepLink else { return }
        pendingDeepLink = nil
        processDeepLink(url)
    }

    // MARK: - Route Handling

    /// Routes a parsed AppRoute to the appropriate child coordinator.
    ///
    /// Pattern:
    /// - Switch to appropriate tab
    /// - If nested route exists, delegate to child coordinator's handle(deepLink:)
    ///
    /// Example:
    /// - AppRoute.accounts(.detail(accountId: "ACC123"))
    /// - Switch to accounts tab
    /// - Call accountsCoordinator.handle(deepLink: .detail(...))
    /// - AccountsCoordinator builds navigation stack
    ///
    /// - Parameter route: The parsed app route
    func handle(route: AppRoute) {
        switch route {
        case .home(let homeRoute):
            selectedTab = .home
            if let route = homeRoute {
                homeCoordinator.handle(deepLink: route)
            }

        case .accounts(let accountsRoute):
            selectedTab = .accounts
            if let route = accountsRoute {
                accountsCoordinator.handle(deepLink: route)
            }

        case .transfer(let transferRoute):
            selectedTab = .transfer
            if let route = transferRoute {
                transferCoordinator.handle(deepLink: route)
            }

        case .cards(let cardsRoute):
            selectedTab = .cards
            if let route = cardsRoute {
                cardsCoordinator.handle(deepLink: route)
            }

        case .more(let moreRoute):
            selectedTab = .more
            if let route = moreRoute {
                moreCoordinator.handle(deepLink: route)
            }

        case .auth(let authRoute):
            // Auth doesn't have a tab - presented modally
            if let route = authRoute {
                authCoordinator.handle(deepLink: route)
            }
        }
    }

    // MARK: - Logout and Session Management

    /// Logs out the user and resets all navigation state.
    ///
    /// Flow:
    /// 1. Call AuthService.logout() async (fire-and-forget with try?)
    /// 2. Reset all child coordinator navigation stacks (popToRoot)
    /// 3. Return to home tab
    ///
    /// AuthService will publish isAuthenticated = false, triggering RootView to show login.
    func logout() {
        Task {
            try? await dependencyContainer.authService.logout()
        }

        // Reset all navigation stacks
        homeCoordinator.popToRoot()
        accountsCoordinator.popToRoot()
        transferCoordinator.popToRoot()
        cardsCoordinator.popToRoot()
        moreCoordinator.popToRoot()

        // Return to home tab
        selectedTab = .home
    }

    /// Handles session expiration by clearing all navigation state and presenting session expired modal.
    /// (Story 2.6 AC: #4, #7, #8)
    ///
    /// Flow:
    /// 1. Clear ALL feature coordinator navigation stacks (popToRoot for each)
    /// 2. Dismiss any presented sheets/fullscreen covers on each coordinator
    /// 3. Reset selected tab to .home
    /// 4. Set isAuthenticated = false (AuthService has already done this)
    /// 5. Present session expired view as full-screen cover
    ///
    /// Called by:
    /// - AuthService.handleSessionExpired() triggers isAuthenticated = false
    /// - observeAuthState() sink detects change and calls this method
    /// - OR called directly by services detecting expired session (HTTP 401)
    ///
    /// Important:
    /// - Must clear navigation BEFORE presenting modal for clean slate
    /// - Fullscreen cover cannot be dismissed without "Log in Again" action
    func sessionExpired() {
        // AC: #7 - Clear all feature coordinator navigation stacks
        homeCoordinator.popToRoot()
        accountsCoordinator.popToRoot()
        transferCoordinator.popToRoot()
        cardsCoordinator.popToRoot()
        moreCoordinator.popToRoot()
        authCoordinator.popToRoot()

        // AC: #7 - Dismiss any presented sheets/fullscreen covers on each coordinator
        homeCoordinator.dismiss()
        accountsCoordinator.dismiss()
        transferCoordinator.dismiss()
        cardsCoordinator.dismiss()
        moreCoordinator.dismiss()

        // AC: #7 - Reset tab to home
        selectedTab = .home

        // AC: #4 - Set isAuthenticated = false
        // Note: AuthService.handleSessionExpired() already sets this, but we set it here
        // in case sessionExpired() is called directly (e.g., HTTP 401 detection)
        isAuthenticated = false

        // AC: #8 - Present session expired view as full-screen cover
        // Uses NavigationItem type-erasing wrapper for AuthRoute
        presentedFullScreen = NavigationItem(AuthRoute.sessionExpired)
    }
}
