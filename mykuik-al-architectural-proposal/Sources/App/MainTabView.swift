import SwiftUI

struct MainTabView: View {
    @ObservedObject var coordinator: AppCoordinator

    var body: some View {
        TabView(selection: $coordinator.selectedTab) {
            coordinator.homeCoordinator.rootView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                .tag(AppTab.home)

            coordinator.accountsCoordinator.rootView()
                .tabItem {
                    Label("Accounts", systemImage: "list.bullet.rectangle")
                }
                .tag(AppTab.accounts)

            coordinator.transferCoordinator.rootView()
                .tabItem {
                    Label("Transfer", systemImage: "arrow.left.arrow.right")
                }
                .tag(AppTab.transfer)

            coordinator.cardsCoordinator.rootView()
                .tabItem {
                    Label("Cards", systemImage: "creditcard.fill")
                }
                .tag(AppTab.cards)

            coordinator.moreCoordinator.rootView()
                .tabItem {
                    Label("More", systemImage: "ellipsis.circle.fill")
                }
                .tag(AppTab.more)
        }
    }
}
