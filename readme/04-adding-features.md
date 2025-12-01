# Adding New Features

This guide provides a step-by-step workflow for implementing new features in the MVVM-C-R architecture. Follow these steps to ensure consistency with existing patterns.

## Overview

Adding a new feature (or screens within an existing feature) follows this sequence:

1. Create feature route file with enum + parser
2. Register in AppRoute and DeepLinkParser
3. Create/Update Coordinator
4. Create/Update ViewFactory
5. Create ViewModel(s)
6. Create View(s)
7. Wire up in AppCoordinator

---

## Step 1: Create Feature Route File

Routes define all possible navigation destinations within a feature. Each feature has its own route file containing the route enum and its parser.

**Location:** `Sources/Router/YourFeatureRoute.swift`

### Create Route File with Enum + Parser

```swift
import Foundation

// MARK: - YourFeatureRoute

enum YourFeatureRoute: Route {
    case list                           // Root screen
    case detail(itemId: String)         // Detail with parameter
    case settings                       // Simple screen
    case edit(itemId: String, mode: EditMode)  // Multiple parameters

    var id: String {
        switch self {
        case .list:
            return "yourFeature-list"
        case .detail(let itemId):
            return "yourFeature-detail-\(itemId)"
        case .settings:
            return "yourFeature-settings"
        case .edit(let itemId, let mode):
            return "yourFeature-edit-\(itemId)-\(mode)"
        }
    }

    var path: String {
        switch self {
        case .list:
            return "yourFeature"
        case .detail(let itemId):
            return "yourFeature/\(itemId)"
        case .settings:
            return "yourFeature/settings"
        case .edit(let itemId, _):
            return "yourFeature/\(itemId)/edit"
        }
    }
}

// MARK: - YourFeatureRoute Parser

extension YourFeatureRoute {
    static func parse(_ components: [String]) -> Result<AppRoute, DeepLinkError> {
        guard !components.isEmpty, components[0] == "yourFeature" else {
            return .failure(.invalidPath)
        }

        if components.count == 1 {
            return .success(.yourFeature(.list))
        } else if components.count == 2 {
            if components[1] == "settings" {
                return .success(.yourFeature(.settings))
            }
            return .success(.yourFeature(.detail(itemId: components[1])))
        } else if components.count == 3 && components[2] == "edit" {
            return .success(.yourFeature(.edit(itemId: components[1], mode: .update)))
        }

        return .failure(.invalidPath)
    }
}
```

### Key Points
- `id`: Unique identifier for NavigationItem equality checks
- `path`: URL path representation for deep linking
- `parse()`: Static method that parses URL components into route
- Associated values should be primitive types (String, Int) for Hashable conformance
- Each route file is self-contained with both enum and parser

---

## Step 2: Register in AppRoute and DeepLinkParser

After creating your feature route file, register it in two places:

### Add to AppRoute

**Location:** `Sources/Router/AppRoute.swift`

```swift
enum AppRoute: Route {
    case home(HomeRoute?)
    case accounts(AccountsRoute?)
    // ... existing cases
    case yourFeature(YourFeatureRoute?)  // Add your feature

    var id: String {
        switch self {
        // ... existing cases
        case .yourFeature(let route):
            return route?.id ?? "app-yourFeature"
        }
    }

    var path: String {
        switch self {
        // ... existing cases
        case .yourFeature(let route):
            return route?.path ?? "yourFeature"
        }
    }
}
```

### Register in DeepLinkParser

**Location:** `Sources/Router/DeepLinkParser.swift`

```swift
struct DeepLinkParser {
    static func parse(_ url: URL) -> Result<AppRoute, DeepLinkError> {
        // ... validation code

        switch first {
        case "home", "notifications":
            return HomeRoute.parse(components)
        case "accounts":
            return AccountsRoute.parse(components)
        // ... existing cases
        case "yourFeature":                          // Add your feature
            return YourFeatureRoute.parse(components)
        default:
            return .failure(.invalidPath)
        }
    }
}
```

---

## Step 3: Create/Update Coordinator

Coordinators manage navigation state and delegate view construction to ViewFactory.

**Location:** `Sources/Coordinator/Features/YourFeatureCoordinator.swift`

### Coordinator Template

```swift
import Foundation
import SwiftUI
import Combine

final class YourFeatureCoordinator: ObservableObject {

    // MARK: - Published State

    @Published var navigationStack: [NavigationItem] = []
    @Published var presentedSheet: NavigationItem?
    @Published var presentedFullScreen: NavigationItem?

    // MARK: - Parent Reference (MUST be weak)

    private weak var parent: AppCoordinator?
    var childCoordinators: [String: AnyObject] = [:]

    // MARK: - Dependencies

    private let dependencyContainer: DependencyContainer
    private let viewFactory: YourFeatureViewFactory

    // MARK: - Initialization

    init(parent: AppCoordinator, dependencyContainer: DependencyContainer) {
        self.parent = parent
        self.dependencyContainer = dependencyContainer
        self.viewFactory = YourFeatureViewFactory(dependencyContainer: dependencyContainer)
    }

    // MARK: - Navigation Methods

    func push(_ route: YourFeatureRoute) {
        navigationStack.append(NavigationItem(route))
    }

    func pop() {
        guard !navigationStack.isEmpty else { return }
        navigationStack.removeLast()
    }

    func popToRoot() {
        navigationStack.removeAll()
    }

    func present(_ route: YourFeatureRoute, fullScreen: Bool = false) {
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

    // MARK: - Cross-Feature Navigation

    func navigateToOtherFeature(with param: String) {
        parent?.switchTab(.otherFeature)
        parent?.otherFeatureCoordinator.push(.someRoute(param: param))
    }

    // MARK: - Deep Link Handling

    func handle(deepLink route: YourFeatureRoute) {
        popToRoot()

        switch route {
        case .list:
            break  // Already at root
        case .detail(let itemId):
            push(.detail(itemId: itemId))
        case .settings:
            push(.settings)
        case .edit(let itemId, let mode):
            push(.detail(itemId: itemId))
            push(.edit(itemId: itemId, mode: mode))
        }
    }

    // MARK: - View Building

    @ViewBuilder
    func build(_ route: YourFeatureRoute) -> some View {
        switch route {
        case .list:
            viewFactory.makeListView(coordinator: self)
        case .detail(let itemId):
            viewFactory.makeDetailView(itemId: itemId, coordinator: self)
        case .settings:
            viewFactory.makeSettingsView(coordinator: self)
        case .edit(let itemId, let mode):
            viewFactory.makeEditView(itemId: itemId, mode: mode, coordinator: self)
        }
    }

    @ViewBuilder
    func rootView() -> some View {
        YourFeatureCoordinatorView(coordinator: self)
    }
}
```

### CoordinatorView Template (iOS 15 Navigation)

```swift
struct YourFeatureCoordinatorView: View {
    @ObservedObject var coordinator: YourFeatureCoordinator

    var body: some View {
        NavigationView {
            coordinator.build(.list)
                .background(navigationLinks)
        }
        .navigationViewStyle(.stack)
        .sheet(item: $coordinator.presentedSheet) { item in
            if let route = item.route.base as? YourFeatureRoute {
                NavigationView {
                    coordinator.build(route)
                }
            }
        }
        .fullScreenCover(item: $coordinator.presentedFullScreen) { item in
            if let route = item.route.base as? YourFeatureRoute {
                NavigationView {
                    coordinator.build(route)
                }
            }
        }
    }

    @ViewBuilder
    private var navigationLinks: some View {
        if let firstItem = coordinator.navigationStack.first,
           let route = firstItem.route.base as? YourFeatureRoute {
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

    private func nestedLinks(from index: Int) -> AnyView {
        if index < coordinator.navigationStack.count,
           let route = coordinator.navigationStack[index].route.base as? YourFeatureRoute {
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

    private func binding(for index: Int) -> Binding<Bool> {
        Binding(
            get: { index < coordinator.navigationStack.count },
            set: { isActive in
                if !isActive && index < coordinator.navigationStack.count {
                    coordinator.navigationStack = Array(coordinator.navigationStack.prefix(index))
                }
            }
        )
    }
}
```

---

## Step 4: Create ViewFactory

ViewFactory creates View+ViewModel pairs, injecting dependencies and coordinator references.

**Location:** `Sources/ViewFactory/YourFeatureViewFactory.swift`

```swift
import SwiftUI

final class YourFeatureViewFactory {
    private let dependencyContainer: DependencyContainer

    // Optional: Cache ViewModels if needed for state preservation
    private var cachedListViewModel: YourListViewModel?

    init(dependencyContainer: DependencyContainer) {
        self.dependencyContainer = dependencyContainer
    }

    func clearCache() {
        cachedListViewModel = nil
    }

    // MARK: - View Creation

    func makeListView(coordinator: YourFeatureCoordinator) -> some View {
        if cachedListViewModel == nil {
            cachedListViewModel = YourListViewModel(
                service: dependencyContainer.yourService,
                coordinator: coordinator
            )
        }
        return YourListView(viewModel: cachedListViewModel!)
    }

    func makeDetailView(itemId: String, coordinator: YourFeatureCoordinator) -> some View {
        let viewModel = YourDetailViewModel(
            itemId: itemId,
            service: dependencyContainer.yourService,
            coordinator: coordinator
        )
        return YourDetailView(viewModel: viewModel)
    }

    func makeSettingsView(coordinator: YourFeatureCoordinator) -> some View {
        let viewModel = YourSettingsViewModel(
            service: dependencyContainer.yourService,
            coordinator: coordinator
        )
        return YourSettingsView(viewModel: viewModel)
    }

    func makeEditView(itemId: String, mode: EditMode, coordinator: YourFeatureCoordinator) -> some View {
        let viewModel = YourEditViewModel(
            itemId: itemId,
            mode: mode,
            service: dependencyContainer.yourService,
            coordinator: coordinator
        )
        return YourEditView(viewModel: viewModel)
    }
}
```

### Caching Strategy
- **Cache list ViewModels**: Preserves scroll position and loaded data
- **Don't cache detail ViewModels**: Fresh data on each visit (unless specific need)
- **Always clear cache on logout**: Prevents stale user data

---

## Step 5: Create ViewModel

ViewModels contain business logic, state management, and navigation delegation.

**Location:** `Sources/ViewModels/YourFeature/YourDetailViewModel.swift`

```swift
import Foundation
import Combine
import OSLog

final class YourDetailViewModel: ObservableObject {

    // MARK: - Published Properties (UI State)

    @Published var item: YourItem?
    @Published var isLoading = false
    @Published var isRefreshing = false
    @Published var error: Error?

    // MARK: - Properties

    let itemId: String

    // MARK: - Dependencies

    private let service: YourServiceProtocol
    weak var coordinator: YourFeatureCoordinator?  // MUST be weak

    // MARK: - Initialization

    init(
        itemId: String,
        service: YourServiceProtocol,
        coordinator: YourFeatureCoordinator?
    ) {
        self.itemId = itemId
        self.service = service
        self.coordinator = coordinator
    }

    // MARK: - Data Loading

    @MainActor
    func loadData() async {
        isLoading = true
        error = nil
        defer { isLoading = false }

        do {
            item = try await service.fetchItem(id: itemId)
            Logger.yourFeature.debug("Loaded item \(self.itemId)")
        } catch {
            self.error = error
            Logger.yourFeature.error("Failed to load item \(self.itemId): \(error.localizedDescription)")
        }
    }

    @MainActor
    func refresh() async {
        isRefreshing = true
        defer { isRefreshing = false }

        do {
            item = try await service.fetchItem(id: itemId)
            error = nil
        } catch {
            self.error = error
        }
    }

    // MARK: - Navigation (Delegated to Coordinator)

    func showSettings() {
        coordinator?.push(.settings)
    }

    func editItem() {
        coordinator?.push(.edit(itemId: itemId, mode: .update))
    }

    func goBack() {
        coordinator?.pop()
    }

    // MARK: - Cross-Feature Navigation

    func navigateToRelatedFeature() {
        coordinator?.navigateToOtherFeature(with: itemId)
    }
}
```

### ViewModel Rules
1. **Weak coordinator reference**: Prevents retain cycles
2. **@MainActor for async methods**: Ensures UI updates on main thread
3. **Separate loading states**: `isLoading` for initial load, `isRefreshing` for pull-to-refresh
4. **Error handling**: Store error for View to display
5. **Use Logger**: Never use `print()` statements

---

## Step 6: Create View

Views are pure SwiftUI with no business logic - only UI rendering.

**Location:** `Sources/Views/YourFeature/YourDetailView.swift`

```swift
import SwiftUI

struct YourDetailView: View {
    @ObservedObject var viewModel: YourDetailViewModel

    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.item == nil {
                LoadingView()
            } else if let item = viewModel.item {
                content(item: item)
            } else if viewModel.error != nil {
                ErrorView(
                    message: "Unable to load item",
                    retryAction: { Task { await viewModel.loadData() } }
                )
            } else {
                EmptyStateView(
                    title: "No Data",
                    message: "Item not found"
                )
            }
        }
        .navigationTitle("Item Detail")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Edit") {
                    viewModel.editItem()
                }
            }
        }
        .task {
            await viewModel.loadData()
        }
        .refreshable {
            await viewModel.refresh()
        }
    }

    @ViewBuilder
    private func content(item: YourItem) -> some View {
        ScrollView {
            VStack(spacing: 16) {
                // Your UI components here
                Text(item.name)
                    .font(.title)

                // Action buttons
                Button("Settings") {
                    viewModel.showSettings()
                }
                .buttonStyle(.bordered)
            }
            .padding()
        }
    }
}
```

### View Rules
1. **@ObservedObject** (not @StateObject): ViewModel created by ViewFactory
2. **Handle all states**: Loading, Content, Error, Empty
3. **Use `.task`**: Auto-cancels on view disappear
4. **Use `.refreshable`**: Standard pull-to-refresh pattern
5. **No navigation logic**: Delegate all navigation to ViewModel

---

## Step 7: Wire Up in Parent Coordinator

Register your coordinator in AppCoordinator.

**Location:** `Sources/Coordinator/AppCoordinator.swift`

```swift
// Add property
@Published private(set) var yourFeatureCoordinator: YourFeatureCoordinator!

// Initialize in setupChildCoordinators()
yourFeatureCoordinator = YourFeatureCoordinator(
    parent: self,
    dependencyContainer: dependencyContainer
)

// Add to handle(route:) switch
case .yourFeature(let route):
    selectedTab = .yourFeature
    if let route = route {
        yourFeatureCoordinator.handle(deepLink: route)
    }
```

### Add to MainTabView

```swift
TabView(selection: $appCoordinator.selectedTab) {
    // ... existing tabs

    appCoordinator.yourFeatureCoordinator.rootView()
        .tabItem {
            Image(systemName: "star")
            Text("Your Feature")
        }
        .tag(AppTab.yourFeature)
}
```

---

## Checklist

Before marking your feature complete, verify:

- [ ] Feature route file created with enum + `parse()` method
- [ ] Route registered in `AppRoute.swift`
- [ ] Route registered in `DeepLinkParser.swift`
- [ ] Coordinator with all navigation methods (push, pop, popToRoot, present, dismiss)
- [ ] CoordinatorView with iOS 15 NavigationLink pattern
- [ ] ViewFactory creating View+ViewModel pairs
- [ ] ViewModels with weak coordinator reference
- [ ] Views handling all states (loading, content, error, empty)
- [ ] Logger statements (no print())
- [ ] Pull-to-refresh on data views
- [ ] Cross-feature navigation via parent coordinator

---

## Quick Reference: File Locations

| Component | Location |
|-----------|----------|
| Feature Routes | `Sources/Router/{Feature}Route.swift` |
| App Route | `Sources/Router/AppRoute.swift` |
| Deep Link Parser | `Sources/Router/DeepLinkParser.swift` |
| Coordinator | `Sources/Coordinator/Features/{Feature}Coordinator.swift` |
| ViewFactory | `Sources/ViewFactory/{Feature}ViewFactory.swift` |
| ViewModels | `Sources/ViewModels/{Feature}/*.swift` |
| Views | `Sources/Views/{Feature}/*.swift` |
| Services | `Sources/Services/Protocols/*.swift` + `Implementations/*.swift` |
