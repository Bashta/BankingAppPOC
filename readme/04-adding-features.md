# Adding New Features

This guide provides a step-by-step workflow for implementing new features in the MVVM-C architecture. Follow these steps to ensure consistency with existing patterns.

## Overview

Adding a new feature (or screens within an existing feature) follows this sequence:

1. Define Route enum cases
2. Create/Update Coordinator
3. Create/Update ViewFactory
4. Create ViewModel(s)
5. Create View(s)
6. Wire up navigation
7. Add deep link support

---

## Step 1: Define Routes

Routes define all possible navigation destinations within a feature. Each route must be unique and hashable.

**Location:** `Sources/Router/Routes.swift`

### Add Route Cases

```swift
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
```

### Key Points
- `id`: Unique identifier for NavigationItem equality checks
- `path`: URL path representation for deep linking
- Associated values should be primitive types (String, Int) for Hashable conformance

---

## Step 2: Create/Update Coordinator

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

## Step 3: Create ViewFactory

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

## Step 4: Create ViewModel

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

## Step 5: Create View

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

## Step 6: Wire Up in Parent Coordinator

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

## Step 7: Add Deep Link Support

Update DeepLinkParser to handle your feature's URLs.

**Location:** `Sources/Router/Routes.swift`

```swift
// In DeepLinkParser.parse(_:)
case "yourFeature":
    return parseYourFeatureRoute(components)

// Add parser method
private static func parseYourFeatureRoute(_ components: [String]) -> Result<AppRoute, DeepLinkError> {
    if components.count == 1 {
        return .success(.yourFeature(.list))
    } else if components.count == 2 {
        return .success(.yourFeature(.detail(itemId: components[1])))
    } else if components.count == 3 && components[2] == "settings" {
        return .success(.yourFeature(.settings))
    }
    return .failure(.invalidPath)
}
```

### Test Deep Links
```
bankapp://yourFeature
bankapp://yourFeature/ITEM123
bankapp://yourFeature/ITEM123/settings
```

---

## Checklist

Before marking your feature complete, verify:

- [ ] Route enum with unique `id` and `path` for each case
- [ ] Coordinator with all navigation methods (push, pop, popToRoot, present, dismiss)
- [ ] CoordinatorView with iOS 15 NavigationLink pattern
- [ ] ViewFactory creating View+ViewModel pairs
- [ ] ViewModels with weak coordinator reference
- [ ] Views handling all states (loading, content, error, empty)
- [ ] Deep link parser updated
- [ ] Logger statements (no print())
- [ ] Pull-to-refresh on data views
- [ ] Cross-feature navigation via parent coordinator

---

## Quick Reference: File Locations

| Component | Location |
|-----------|----------|
| Routes | `Sources/Router/Routes.swift` |
| Coordinator | `Sources/Coordinator/Features/{Feature}Coordinator.swift` |
| ViewFactory | `Sources/ViewFactory/{Feature}ViewFactory.swift` |
| ViewModels | `Sources/ViewModels/{Feature}/*.swift` |
| Views | `Sources/Views/{Feature}/*.swift` |
| Services | `Sources/Services/Protocols/*.swift` + `Implementations/*.swift` |
