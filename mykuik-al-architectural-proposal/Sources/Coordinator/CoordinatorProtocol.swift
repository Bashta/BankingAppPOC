import Foundation
import SwiftUI

// MARK: - Coordinator Protocol
//
// This protocol defines the common interface for all coordinators in the MVVM-C architecture.
// While this protocol is optional in our implementation, it serves as documentation of the
// coordinator pattern and provides a common contract that all coordinators should follow.
//
// Key Responsibilities of Coordinators:
// - Manage navigation state (@Published properties for navigation stack, sheets, fullScreenCovers)
// - Build views for their feature's routes
// - Handle deep linking within their feature
// - Provide navigation methods (push, pop, present, dismiss)
// - Maintain weak parent reference to prevent retain cycles
// - Own ViewFactory instance for dependency injection
//
// Pattern: All coordinators are final classes conforming to ObservableObject
// Memory Management: Parent holds strong reference to child, child holds weak reference to parent

protocol CoordinatorProtocol: ObservableObject {
    // Type of routes this coordinator handles
    associatedtype RouteType: Route

    // Navigation state - published for SwiftUI observation
    var navigationStack: [NavigationItem] { get set }
    var presentedSheet: NavigationItem? { get set }
    var presentedFullScreen: NavigationItem? { get set }

    // Navigation methods
    func push(_ route: RouteType)
    func pop()
    func popToRoot()
    func present(_ route: RouteType, fullScreen: Bool)
    func dismiss()

    // Deep link handling
    func handle(deepLink route: RouteType)

    // View building
    @ViewBuilder func build(_ route: RouteType) -> AnyView
    @ViewBuilder func rootView() -> AnyView
}

// MARK: - Default Implementations
//
// Provides default implementations for common navigation operations.
// Coordinators can override these if custom behavior is needed.

extension CoordinatorProtocol {
    func pop() {
        guard !navigationStack.isEmpty else { return }
        navigationStack.removeLast()
    }

    func popToRoot() {
        navigationStack.removeAll()
    }

    func present(_ route: RouteType, fullScreen: Bool = false) {
        let item = NavigationItem(route)
        if fullScreen {
            presentedFullScreen = item
        } else {
            presentedSheet = item
        }
    }

    func dismiss() {
        presentedSheet = nil
        presentedFullScreen = nil
    }
}
