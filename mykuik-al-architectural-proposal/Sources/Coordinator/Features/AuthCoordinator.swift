import Foundation
import SwiftUI
import Combine

// MARK: - AuthCoordinator

/// Coordinator for the Authentication feature (modal presentation).
///
/// Responsibilities:
/// - Manages navigation within Auth flows (login, biometric, OTP, forgot password, reset password, session expired)
/// - Owns AuthViewFactory for view construction
/// - Handles deep links to auth-related screens
/// - Presented modally over tabs (not a tab itself)
///
/// Navigation Stack:
/// - Root: Login Screen
/// - Can push: Biometric Login, OTP, Forgot Password, Reset Password, Session Expired
///
/// Architecture Note:
/// - Auth is presented full-screen over the main tabs when user is not authenticated
/// - After successful authentication, RootView transitions to MainTabView
/// - No persistent tab; auth is transient authentication state
///
/// iOS 15 Pattern:
/// - Uses NavigationView with hidden NavigationLinks
/// - Recursive nestedLinks pattern for unlimited depth
/// - Binding synchronization for back button handling
final class AuthCoordinator: ObservableObject {

    // MARK: - Published State

    /// Navigation stack for programmatic navigation. Holds NavigationItem wrappers.
    @Published var navigationStack: [NavigationItem] = []

    /// Modal sheet presentation. Used for quick actions or secondary flows.
    @Published var presentedSheet: NavigationItem?

    /// Full-screen modal presentation. Used for immersive flows.
    @Published var presentedFullScreen: NavigationItem?

    // MARK: - Parent Reference

    /// Weak reference to AppCoordinator.
    /// NOTE: Auth coordinator has minimal parent interaction since it's presented modally.
    /// Parent mainly uses this coordinator when presenting session expired screen.
    private weak var parent: AppCoordinator?

    /// Child coordinator storage (optional pattern, not heavily used in this implementation).
    var childCoordinators: [String: AnyObject] = [:]

    // MARK: - Dependencies

    /// Dependency container providing service access.
    private let dependencyContainer: DependencyContainer

    /// View factory for creating Auth feature views with ViewModels.
    private let viewFactory: AuthViewFactory

    // MARK: - Initialization

    /// Creates AuthCoordinator with parent and dependencies.
    ///
    /// - Parameters:
    ///   - parent: AppCoordinator reference (weak)
    ///   - dependencyContainer: Service container
    init(parent: AppCoordinator, dependencyContainer: DependencyContainer) {
        self.parent = parent
        self.dependencyContainer = dependencyContainer
        self.viewFactory = AuthViewFactory(dependencyContainer: dependencyContainer)
    }

    // MARK: - Navigation Methods

    /// Pushes a route onto the navigation stack.
    ///
    /// - Parameter route: The AuthRoute to navigate to
    func push(_ route: AuthRoute) {
        navigationStack.append(NavigationItem(route))
    }

    /// Pops the top route from the navigation stack.
    /// Defensive: does nothing if stack is empty.
    func pop() {
        guard !navigationStack.isEmpty else { return }
        navigationStack.removeLast()
    }

    /// Clears the entire navigation stack, returning to root (login).
    func popToRoot() {
        navigationStack.removeAll()
    }

    /// Presents a route modally (sheet or full-screen).
    ///
    /// - Parameters:
    ///   - route: The AuthRoute to present
    ///   - fullScreen: If true, uses fullScreenCover; otherwise uses sheet
    func present(_ route: AuthRoute, fullScreen: Bool = false) {
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

    /// Handles deep links to Auth feature screens.
    ///
    /// Pattern:
    /// 1. Always popToRoot() first to clear existing stack
    /// 2. Build navigation stack by pushing routes in order
    ///
    /// Examples:
    /// - .login → Already at root, do nothing
    /// - .biometric → Push biometric login
    /// - .otp(reference) → Push OTP entry (usually after login attempt)
    /// - .forgotPassword → Push forgot password
    /// - .resetPassword(token) → Push reset password with token
    /// - .sessionExpired → Push session expired screen
    ///
    /// Note: Deep links to auth screens are less common since auth is modal.
    /// Most auth navigation is flow-based (login → OTP → success).
    ///
    /// - Parameter route: The AuthRoute from deep link
    func handle(deepLink route: AuthRoute) {
        popToRoot()

        switch route {
        case .login:
            // Already at root login
            break

        case .biometric:
            push(.biometric)

        case .otp(let reference):
            // Direct to OTP (unusual, but supported)
            push(.otp(reference: reference))

        case .forgotPassword:
            push(.forgotPassword)

        case .resetPassword(let token):
            // Direct to reset password with token
            push(.resetPassword(token: token))

        case .sessionExpired:
            // Session expired screen (usually presented by AppCoordinator)
            push(.sessionExpired)
        }
    }

    // MARK: - View Building

    /// Builds the view for a given route using ViewFactory.
    ///
    /// Called by AuthCoordinatorView for each route in navigation stack and modals.
    ///
    /// - Parameter route: The AuthRoute to build a view for
    /// - Returns: The SwiftUI view for the route
    @ViewBuilder
    func build(_ route: AuthRoute) -> some View {
        switch route {
        case .login:
            viewFactory.makeLoginView(coordinator: self)

        case .biometric:
            viewFactory.makeBiometricLoginView(coordinator: self)

        case .otp(let reference):
            let otpRef = OTPReference(
                id: reference,
                expiresAt: Date().addingTimeInterval(300),
                purpose: .login
            )
            viewFactory.makeOTPView(otpReference: otpRef, coordinator: self)

        case .forgotPassword:
            viewFactory.makeForgotPasswordView(coordinator: self)

        case .resetPassword(let token):
            viewFactory.makeResetPasswordView(token: token, coordinator: self)

        case .sessionExpired:
            viewFactory.makeSessionExpiredView(coordinator: self)
        }
    }

    /// Returns the root CoordinatorView for this feature.
    ///
    /// Called by RootView when user is not authenticated.
    ///
    /// - Returns: AuthCoordinatorView with this coordinator
    @ViewBuilder
    func rootView() -> some View {
        AuthCoordinatorView(coordinator: self)
    }
}

// MARK: - AuthCoordinatorView

/// SwiftUI view wrapper for AuthCoordinator implementing iOS 15 recursive navigation pattern.
///
/// Pattern Details:
/// - NavigationView with .stack style (required for iOS 15)
/// - Root view: coordinator.build(.login)
/// - Hidden NavigationLinks in background for programmatic navigation
/// - Recursive nestedLinks function enables unlimited depth
/// - Binding synchronization handles back button pops
///
/// Memory:
/// - @ObservedObject (not @StateObject) - coordinator created by AppCoordinator
struct AuthCoordinatorView: View {
    @ObservedObject var coordinator: AuthCoordinator

    var body: some View {
        NavigationView {
            coordinator.build(.login)
                .background(navigationLinks)
        }
        .navigationViewStyle(.stack)
        .sheet(item: $coordinator.presentedSheet) { item in
            if let route = item.route.base as? AuthRoute {
                NavigationView {
                    coordinator.build(route)
                }
            }
        }
        .fullScreenCover(item: $coordinator.presentedFullScreen) { item in
            if let route = item.route.base as? AuthRoute {
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
            if let route = item.route.base as? AuthRoute {
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
           let route = coordinator.navigationStack[index].route.base as? AuthRoute {
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
