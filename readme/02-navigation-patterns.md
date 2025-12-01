# Navigation Patterns

This document explains the iOS 15-compatible navigation system used throughout the application, including the coordinator pattern, hidden NavigationLink approach, and deep linking.

---

## Why NavigationView (Not NavigationStack)

The app targets **iOS 15.0** as the minimum deployment version. Apple introduced `NavigationStack` and `navigationDestination(for:)` in **iOS 16**, making them unavailable for our use.

**What we CAN'T use (iOS 16+ only):**
```swift
// NOT AVAILABLE on iOS 15
NavigationStack(path: $path) {
    RootView()
        .navigationDestination(for: Route.self) { route in
            // ...
        }
}
```

**What we use instead:**
```swift
// iOS 15 compatible
NavigationView {
    rootView
        .background(navigationLinks)  // Hidden links
}
.navigationViewStyle(.stack)
```

---

## Coordinator Navigation State

Each feature coordinator manages navigation through `@Published` properties:

```swift
final class AccountsCoordinator: ObservableObject {
    /// Stack of pushed views (programmatic navigation)
    @Published var navigationStack: [NavigationItem] = []

    /// Currently presented sheet (modal)
    @Published var presentedSheet: NavigationItem?

    /// Currently presented full-screen cover
    @Published var presentedFullScreen: NavigationItem?
}
```

### NavigationItem

Routes are wrapped in `NavigationItem` for the navigation stack:

```swift
struct NavigationItem: Identifiable, Equatable {
    let id: UUID              // Unique per push (enables same route multiple times)
    let route: AnyHashable    // Type-erased route

    init<R: Route>(_ route: R) {
        self.id = UUID()
        self.route = AnyHashable(route)
    }
}
```

---

## Navigation Methods

Every coordinator implements these standard methods:

### push(_:)
Adds a route to the navigation stack:
```swift
func push(_ route: AccountsRoute) {
    navigationStack.append(NavigationItem(route))
}

// Usage in ViewModel
coordinator?.push(.detail(accountId: "ACC123"))
```

### pop()
Removes the top route from the stack:
```swift
func pop() {
    guard !navigationStack.isEmpty else { return }
    navigationStack.removeLast()
}
```

### popToRoot()
Clears the entire navigation stack:
```swift
func popToRoot() {
    navigationStack.removeAll()
}
```

### present(_:fullScreen:)
Shows a modal:
```swift
func present(_ route: AccountsRoute, fullScreen: Bool = false) {
    let item = NavigationItem(route)
    if fullScreen {
        presentedFullScreen = item
    } else {
        presentedSheet = item
    }
}

// Usage
coordinator?.present(.quickAction, fullScreen: false)  // Sheet
coordinator?.present(.immersiveFlow, fullScreen: true) // Full screen
```

### dismiss()
Closes the current modal:
```swift
func dismiss() {
    presentedSheet = nil
    presentedFullScreen = nil
}
```

---

## Hidden NavigationLink Pattern

The core technique for programmatic navigation on iOS 15 is using **hidden NavigationLinks** that activate based on coordinator state.

### CoordinatorView Structure

```swift
struct AccountsCoordinatorView: View {
    @ObservedObject var coordinator: AccountsCoordinator

    var body: some View {
        NavigationView {
            coordinator.build(.list)          // Root view
                .background(navigationLinks)  // Hidden navigation triggers
        }
        .navigationViewStyle(.stack)          // Required for consistent behavior
        .sheet(item: $coordinator.presentedSheet) { item in
            // Sheet modal handling
        }
        .fullScreenCover(item: $coordinator.presentedFullScreen) { item in
            // Full screen modal handling
        }
    }
}
```

### Navigation Links Implementation

```swift
@ViewBuilder
private var navigationLinks: some View {
    // Only create link for FIRST item in stack
    if let firstItem = coordinator.navigationStack.first,
       let route = firstItem.route.base as? AccountsRoute {
        NavigationLink(
            destination: coordinator.build(route)
                .background(nestedLinks(from: 1)),  // Recursion!
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
```

### Recursive Nested Links

For navigation deeper than one level, we use recursive nested links:

```swift
private func nestedLinks(from index: Int) -> AnyView {
    if index < coordinator.navigationStack.count,
       let route = coordinator.navigationStack[index].route.base as? AccountsRoute {
        return AnyView(
            NavigationLink(
                destination: coordinator.build(route)
                    .background(nestedLinks(from: index + 1)),  // Next level
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
```

### Binding Synchronization

The binding handles back button presses by syncing coordinator state:

```swift
private func binding(for index: Int) -> Binding<Bool> {
    Binding(
        get: { index < coordinator.navigationStack.count },
        set: { isActive in
            if !isActive && index < coordinator.navigationStack.count {
                // User tapped back - truncate stack to this point
                coordinator.navigationStack = Array(coordinator.navigationStack.prefix(index))
            }
        }
    )
}
```

**How it works:**
1. `get`: Returns `true` if this index exists in the stack (link should be active)
2. `set`: When user taps back, SwiftUI sets `isActive = false`
3. We truncate the stack to match the actual navigation state

---

## Navigation Flow Example

### Scenario: List → Detail → Transactions

```
User taps account in list
    │
    ▼
AccountsListViewModel.showAccountDetail(account)
    │
    ▼
coordinator?.push(.detail(accountId: account.id))
    │
    ▼
AccountsCoordinator:
    navigationStack.append(NavigationItem(.detail(accountId: "ACC123")))
    │
    ▼
AccountsCoordinatorView observes change:
    - navigationStack.first exists
    - NavigationLink isActive becomes true
    - AccountDetailView pushed onto navigation stack
    │
    ▼
User taps "View All Transactions"
    │
    ▼
AccountDetailViewModel.showAllTransactions()
    │
    ▼
coordinator?.push(.transactions(accountId: accountId))
    │
    ▼
AccountsCoordinator:
    navigationStack = [.detail(...), .transactions(...)]
    │
    ▼
AccountsCoordinatorView:
    - nestedLinks(from: 1) creates link for transactions
    - TransactionHistoryView pushed onto stack
```

### Scenario: Back Button Press

```
User taps back button (on TransactionHistoryView)
    │
    ▼
SwiftUI sets NavigationLink isActive = false
    │
    ▼
binding(for: 1).set(false) triggered
    │
    ▼
coordinator.navigationStack = prefix(1) = [.detail(...)]
    │
    ▼
View updates, TransactionHistoryView pops off
    │
    ▼
AccountDetailView now visible
```

---

## Cross-Feature Navigation

Navigation between features (tabs) goes through AppCoordinator:

### Pattern

```swift
// In AccountsCoordinator
func navigateToTransfer(fromAccountId: String) {
    parent?.switchTab(.transfer)
    parent?.transferCoordinator.push(.internalTransferWithAccount(fromAccountId: fromAccountId))
}
```

### Flow

```
1. User on Account Detail taps "Transfer"
    │
    ▼
2. AccountDetailViewModel.initiateTransfer()
    │
    ▼
3. AccountsCoordinator.navigateToTransfer(fromAccountId)
    │
    ├─► parent?.switchTab(.transfer)
    │       AppCoordinator.selectedTab = .transfer
    │       MainTabView switches to Transfer tab
    │
    └─► parent?.transferCoordinator.push(...)
            TransferCoordinator navigates to pre-filled form
```

---

## Deep Linking

Deep links allow navigation to any screen via URL.

### URL Scheme
```
bankapp://accounts/ACC123/transactions
```

### Deep Link Flow

```
1. App receives URL via onOpenURL
    │
    ▼
2. AppCoordinator.handle(deepLink: url)
    │
    ├─► Check authentication
    │   └─► If not authenticated, store in pendingDeepLink
    │
    └─► If authenticated, process immediately
            │
            ▼
3. DeepLinkParser.parse(url) → Result<AppRoute, DeepLinkError>
    │
    ▼
4. AppCoordinator.handle(route: appRoute)
    │
    ├─► Switch to correct tab
    └─► Call feature coordinator's handle(deepLink:)
            │
            ▼
5. Feature Coordinator:
    ├─► popToRoot()  // Clear existing stack
    └─► Push routes in order to reach destination
```

### Deep Link Parser

```swift
struct DeepLinkParser {
    static func parse(_ url: URL) -> Result<AppRoute, DeepLinkError> {
        guard url.scheme == "bankapp" else {
            return .failure(.invalidScheme)
        }

        let components = url.pathComponents.filter { $0 != "/" }

        switch components.first {
        case "accounts":
            return parseAccountsRoute(components)
        case "transfer":
            return parseTransferRoute(components)
        // ... other features
        default:
            return .failure(.invalidPath)
        }
    }
}
```

### Feature Deep Link Handler

```swift
// In AccountsCoordinator
func handle(deepLink route: AccountsRoute) {
    popToRoot()  // Always start fresh

    switch route {
    case .list:
        break  // Already at root

    case .detail(let accountId):
        push(.detail(accountId: accountId))

    case .transactions(let accountId):
        // Build navigation hierarchy
        push(.detail(accountId: accountId))
        push(.transactions(accountId: accountId))

    case .transactionDetail(let transactionId):
        push(.transactionDetail(transactionId: transactionId))
    // ...
    }
}
```

### Supported Deep Links

| URL | Route |
|-----|-------|
| `bankapp://home` | Home dashboard |
| `bankapp://accounts` | Accounts list |
| `bankapp://accounts/ACC123` | Account detail |
| `bankapp://accounts/ACC123/transactions` | Transaction history |
| `bankapp://transfer` | Transfer home |
| `bankapp://transfer/internal` | Internal transfer |
| `bankapp://transfer/beneficiaries` | Beneficiary list |
| `bankapp://cards` | Cards list |
| `bankapp://cards/CARD123/settings` | Card settings |
| `bankapp://more/profile` | User profile |
| `bankapp://more/security` | Security settings |

---

## Modal Presentation

### Sheet (Half-screen modal)

```swift
// Present
coordinator?.present(.quickAction, fullScreen: false)

// In CoordinatorView
.sheet(item: $coordinator.presentedSheet) { item in
    if let route = item.route.base as? AccountsRoute {
        NavigationView {
            coordinator.build(route)
        }
    }
}

// Dismiss
coordinator?.dismiss()
```

### Full Screen Cover

```swift
// Present
coordinator?.present(.immersiveFlow, fullScreen: true)

// In CoordinatorView
.fullScreenCover(item: $coordinator.presentedFullScreen) { item in
    if let route = item.route.base as? AccountsRoute {
        NavigationView {
            coordinator.build(route)
        }
    }
}

// Dismiss
coordinator?.dismiss()
```

---

## Common Patterns

### Navigate with Data

```swift
// ViewModel
func showTransactionDetail(_ transaction: Transaction) {
    coordinator?.push(.transactionDetail(transactionId: transaction.id))
}

// Route enum
case transactionDetail(transactionId: String)
```

### Navigate and Dismiss

```swift
// After completing action in modal
func completeAction() async {
    await performAction()
    coordinator?.dismiss()
}
```

### Navigate with Completion

```swift
// For flows that return to previous screen
func saveAndGoBack() async {
    await saveChanges()
    coordinator?.pop()
}
```

### Replace Current Screen

```swift
// Pop current, push new (e.g., success → receipt)
func showReceipt(transferId: String) {
    coordinator?.pop()
    coordinator?.push(.receipt(transferId: transferId))
}
```

---

## Debugging Navigation

### Log Navigation State

```swift
func push(_ route: AccountsRoute) {
    Logger.navigation.debug("Push: \(route.path)")
    navigationStack.append(NavigationItem(route))
    Logger.navigation.debug("Stack depth: \(self.navigationStack.count)")
}

func pop() {
    guard !navigationStack.isEmpty else {
        Logger.navigation.warning("Pop called on empty stack")
        return
    }
    let popped = navigationStack.removeLast()
    Logger.navigation.debug("Popped: \(String(describing: popped.route))")
}
```

### Common Issues

| Symptom | Likely Cause | Solution |
|---------|--------------|----------|
| Back button doesn't work | Binding not syncing | Check `binding(for:).set` implementation |
| Push does nothing | NavigationLink not rendered | Verify `navigationLinks` in background |
| Infinite loop | Recursive links broken | Check `nestedLinks(from:)` termination |
| Modal won't dismiss | Wrong property cleared | Verify `dismiss()` clears correct property |

---

## See Also

- [01-architecture-overview.md](01-architecture-overview.md) - Overall architecture
- [04-adding-features.md](04-adding-features.md) - Implementing new coordinators
- [05-decisions.md](05-decisions.md) - ADR-002: NavigationView decision
