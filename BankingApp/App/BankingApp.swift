import SwiftUI

@main
struct BankingApp: App {
    // Create DependencyContainer once at app launch
    private let container: DependencyContainer

    // Create AppCoordinator with container
    @StateObject private var appCoordinator: AppCoordinator

    init() {
        let container = DependencyContainer()
        self.container = container

        // AppCoordinator receives container via initializer
        _appCoordinator = StateObject(wrappedValue: AppCoordinator(dependencyContainer: container))
    }

    var body: some Scene {
        WindowGroup {
            RootView(coordinator: appCoordinator)
                .onOpenURL { url in
                    appCoordinator.handle(deepLink: url)
                }
        }
    }
}
