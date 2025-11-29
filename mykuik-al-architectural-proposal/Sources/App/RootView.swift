import SwiftUI

struct RootView: View {
    @ObservedObject var coordinator: AppCoordinator

    var body: some View {
        Group {
            if coordinator.isAuthenticated {
                MainTabView(coordinator: coordinator)
            } else {
                coordinator.authCoordinator.rootView()
            }
        }
    }
}
