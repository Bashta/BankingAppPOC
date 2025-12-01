# Architecture Decision Records (ADRs)

This document captures key architectural decisions made during the development of this banking application, including context, rationale, and trade-offs considered.

---

## ADR-001: MVVM-C Architecture Pattern

### Status
Accepted

### Context
We needed an architecture pattern that provides:
- Clear separation of concerns for maintainability
- Testability of business logic
- Support for complex navigation flows (banking apps have deep navigation)
- Consistency for AI-assisted development (multiple agents working on the codebase)
- Scalability for a growing feature set

Alternatives considered:
- **MVC**: Too coupled, difficult to test, navigation mixed with presentation
- **VIPER**: Over-engineered for this scope, too many layers
- **TCA (The Composable Architecture)**: Learning curve, external dependency, opinionated state management
- **Clean Architecture**: More layers than needed for this POC

### Decision
Adopt **MVVM-C** (Model-View-ViewModel-Coordinator) with these responsibilities:
- **Model**: Domain objects (Account, Transaction, Card)
- **View**: SwiftUI views (UI only, no business logic)
- **ViewModel**: Business logic, state management, navigation delegation
- **Coordinator**: Navigation logic, view factory ownership, deep link handling

### Consequences
**Positive:**
- Clear boundaries enable parallel development
- ViewModels are easily testable (no UI dependencies)
- Navigation logic is centralized and predictable
- AI agents can work consistently across features

**Negative:**
- More files per feature than simpler patterns
- Coordinator boilerplate for each feature
- Learning curve for developers unfamiliar with coordinator pattern

---

## ADR-002: NavigationView for iOS 15 Compatibility

### Status
Accepted

### Context
The app must support iOS 15.0 as the minimum deployment target. Apple introduced `NavigationStack` and `navigationDestination(for:)` in iOS 16, which are not available on iOS 15.

Options:
1. **Require iOS 16+**: Use modern NavigationStack APIs
2. **Use NavigationView**: iOS 15 compatible but less elegant
3. **Hybrid approach**: Conditional compilation based on iOS version

### Decision
Use **NavigationView with hidden NavigationLinks** pattern exclusively. No iOS 16+ navigation APIs.

Implementation pattern:
```swift
NavigationView {
    rootView
        .background(navigationLinks)  // Hidden NavigationLinks
}
.navigationViewStyle(.stack)
```

The navigation stack is managed via `@Published var navigationStack: [NavigationItem]` in coordinators, with hidden `NavigationLink(destination:isActive:)` views that sync with this state.

### Consequences
**Positive:**
- Full iOS 15.0 support
- Single code path (no conditional compilation)
- Consistent behavior across all iOS versions

**Negative:**
- More complex navigation code
- Hidden NavigationLinks pattern is non-obvious
- Manual binding synchronization for back button handling
- More boilerplate than NavigationStack

### Implementation Details
See `AccountsCoordinatorView` for the reference implementation of:
- Recursive `nestedLinks(from:)` for unlimited navigation depth
- `binding(for:)` for back button state synchronization

---

## ADR-003: Weak Coordinator References in ViewModels

### Status
Accepted

### Context
The coordinator hierarchy creates potential for retain cycles:
```
AppCoordinator → Child Coordinators → ViewFactory → ViewModels → Coordinator (cycle!)
```

If ViewModels hold strong references to Coordinators, neither can be deallocated.

### Decision
All ViewModel references to Coordinators **MUST** be `weak`:

```swift
final class AccountDetailViewModel: ObservableObject {
    weak var coordinator: AccountsCoordinator?  // MUST be weak
    // ...
}
```

### Consequences
**Positive:**
- No retain cycles
- Clean memory management
- Coordinators deallocate properly on logout/tab switching

**Negative:**
- Must use optional chaining for navigation calls (`coordinator?.push(...)`)
- Must remember to use `weak` - compiler won't catch strong references
- ViewModels can't guarantee coordinator exists when navigation is needed

### Enforcement
Code review should verify:
1. All `coordinator` properties in ViewModels are `weak`
2. All closures capturing `coordinator` use `[weak self]`

---

## ADR-004: Mock Services for POC Phase

### Status
Accepted

### Context
This is a Proof of Concept / architectural reference implementation. Real backend APIs are not available during development.

Options:
1. **Build real API integration first**: Delays UI development
2. **Mock services with realistic data**: Enables full UI development
3. **Static data in ViewModels**: Quick but not realistic

### Decision
All services have **protocol definitions** with **mock implementations** that:
- Return realistic banking data (account numbers, transactions, balances)
- Simulate network latency with `Task.sleep`
- Support all expected operations (CRUD, pagination, filtering)

```swift
protocol AccountServiceProtocol {
    func fetchAccounts() async throws -> [Account]
    func fetchAccount(id: String) async throws -> Account
    // ...
}

final class MockAccountService: AccountServiceProtocol {
    func fetchAccounts() async throws -> [Account] {
        try await Task.sleep(nanoseconds: 500_000_000)  // Simulate latency
        return mockAccounts
    }
}
```

### Consequences
**Positive:**
- Full UI development without backend dependency
- Realistic testing of loading states, error handling
- Easy to swap mock for real implementation later
- Services are well-defined via protocols

**Negative:**
- Mock data may not match actual API responses
- Edge cases in real API may be missed
- Must maintain two implementations (mock + real)

### Migration Path
When real APIs are ready:
1. Create `RealAccountService: AccountServiceProtocol`
2. Update `DependencyContainer` to use real implementation
3. Keep mocks for testing/preview

---

## ADR-005: Combine Over External State Management

### Status
Accepted

### Context
State management options for SwiftUI:
1. **@Published + ObservableObject**: Built into iOS 15+
2. **Redux/TCA**: External library, single state tree
3. **ReSwift**: Redux-like, requires middleware
4. **Custom reactive framework**: High maintenance

### Decision
Use **Combine's @Published** with **ObservableObject** pattern:
- Coordinators are `ObservableObject` with `@Published` navigation state
- ViewModels are `ObservableObject` with `@Published` UI state
- Views observe via `@ObservedObject`

```swift
final class AccountDetailViewModel: ObservableObject {
    @Published var account: Account?
    @Published var isLoading = false
    @Published var error: Error?
}

struct AccountDetailView: View {
    @ObservedObject var viewModel: AccountDetailViewModel
}
```

### Consequences
**Positive:**
- No external dependencies
- Built into Swift/SwiftUI
- Simple, well-documented
- Automatic view updates on state changes

**Negative:**
- Less structured than Redux (no single source of truth)
- No time-travel debugging
- State scattered across multiple ViewModels
- No built-in middleware for side effects

### Why Not Redux/TCA?
- Additional learning curve
- Overkill for this scope
- Combine is sufficient for our state management needs
- Keeping dependencies minimal for POC

---

## ADR-006: Per-Feature Coordinators

### Status
Accepted

### Context
Navigation in a banking app is complex:
- 5 main tabs (Home, Accounts, Transfer, Cards, More)
- Deep navigation within each tab
- Cross-tab navigation (e.g., "Transfer from Account" button)
- Deep linking to any screen
- Authentication gating

Options:
1. **Single AppCoordinator**: All navigation in one class
2. **Per-feature coordinators**: Each tab manages its own navigation
3. **Per-screen coordinators**: Maximum granularity

### Decision
**Per-feature coordinators** with parent AppCoordinator:

```
AppCoordinator (root)
├── HomeCoordinator
├── AccountsCoordinator
├── TransferCoordinator
├── CardsCoordinator
├── MoreCoordinator
└── AuthCoordinator
```

Each coordinator manages:
- Its own navigation stack
- Sheet/fullscreen presentations
- Deep link handling for its routes
- View construction delegation

Cross-feature navigation goes through AppCoordinator:
```swift
func navigateToTransfer(fromAccountId: String) {
    parent?.switchTab(.transfer)
    parent?.transferCoordinator.push(.internalTransferWithAccount(fromAccountId: fromAccountId))
}
```

### Consequences
**Positive:**
- Feature isolation (teams can work independently)
- Manageable complexity per coordinator
- Clear ownership of navigation state
- Easy to add new features

**Negative:**
- More files (6 coordinators + views)
- Cross-feature communication requires parent
- Consistent patterns must be enforced manually

---

## ADR-007: Type-Safe Routing

### Status
Accepted

### Context
Navigation destinations can be identified by:
1. **String paths**: Flexible but error-prone ("accounts/detail" vs "account/details")
2. **Type-safe enums**: Compile-time safety, autocomplete support
3. **URL-based routing**: Web-like, but stringly-typed

### Decision
Use **type-safe route enums** with `Hashable` and `Identifiable` conformance:

```swift
enum AccountsRoute: Route {
    case list
    case detail(accountId: String)
    case transactions(accountId: String)
    case transactionDetail(transactionId: String)
    // ...
}
```

Routes wrapped in `NavigationItem` for stack management:
```swift
struct NavigationItem: Identifiable, Equatable {
    let id: UUID
    let route: AnyHashable
}
```

Deep link URLs parsed into route enums via `DeepLinkParser`:
```swift
"bankapp://accounts/ACC123" → AppRoute.accounts(.detail(accountId: "ACC123"))
```

### Consequences
**Positive:**
- Compile-time route validation
- IDE autocomplete for routes
- Impossible to navigate to undefined routes
- Refactoring support (rename route → compiler catches all usages)

**Negative:**
- Route enums grow with feature complexity
- Type erasure needed for heterogeneous navigation stacks
- Deep link parser must be updated for each new route

---

## ADR-008: Lazy Service Initialization

### Status
Accepted

### Context
`DependencyContainer` holds all app services. Initialization options:
1. **Eager**: Create all services at app launch
2. **Lazy**: Create services on first access
3. **Factory**: Create new instance each time

### Decision
Use **lazy initialization** for all services:

```swift
final class DependencyContainer {
    lazy var accountService: AccountServiceProtocol = MockAccountService()
    lazy var authService: AuthServiceProtocol = MockAuthService()
    // ...
}
```

### Consequences
**Positive:**
- Faster app startup (services created when needed)
- Single instance per service (state preserved)
- Proper dependency ordering (services with dependencies initialized after their dependencies)

**Negative:**
- First access has initialization overhead
- Thread safety considerations (though Swift's lazy is thread-safe for reads)
- Order of declaration matters for services with dependencies

### Dependency Ordering Note
Services that depend on other services must be declared after their dependencies:
```swift
lazy var secureStorage: SecureStorageProtocol = KeychainSecureStorage()
lazy var authService: AuthServiceProtocol = MockAuthService()  // May use secureStorage
```

---

## ADR-009: OSLog for Logging

### Status
Accepted

### Context
Logging is essential for debugging. Options:
1. **print()**: Simple but no filtering, always runs
2. **#if DEBUG print()**: Conditional but still no structure
3. **OSLog/Logger**: Apple's recommended, structured, performant
4. **Third-party (CocoaLumberjack, SwiftyBeaver)**: Feature-rich but external dependency

### Decision
Use **OSLog Logger** with feature-specific categories:

```swift
extension Logger {
    static let auth = Logger(subsystem: subsystem, category: "auth")
    static let accounts = Logger(subsystem: subsystem, category: "accounts")
    static let transfer = Logger(subsystem: subsystem, category: "transfer")
    // ...
}

// Usage
Logger.accounts.debug("Loaded account \(accountId)")
Logger.accounts.error("Failed to load: \(error.localizedDescription)")
```

### Consequences
**Positive:**
- Zero overhead in release builds (compiled out)
- Filterable in Console.app by category
- Structured log levels (debug, info, error, fault)
- No external dependencies

**Negative:**
- Not available below iOS 14 (we target iOS 15, so not an issue)
- Less feature-rich than third-party loggers
- Requires discipline to use consistently

### Rule
**Never use `print()` in this codebase.** Always use `Logger.{category}.{level}()`.

---

## Summary Table

| ADR | Decision | Key Trade-off |
|-----|----------|---------------|
| 001 | MVVM-C | More files for better separation |
| 002 | NavigationView | iOS 15 support over modern APIs |
| 003 | Weak coordinator refs | Optional chaining for memory safety |
| 004 | Mock services | Fast development over real API integration |
| 005 | Combine @Published | Simplicity over Redux-style state management |
| 006 | Per-feature coordinators | Isolation over single coordinator simplicity |
| 007 | Type-safe routes | Compile safety over runtime flexibility |
| 008 | Lazy service init | Startup speed over eager initialization |
| 009 | OSLog Logger | Built-in solution over third-party features |
