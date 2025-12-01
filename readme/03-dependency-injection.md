# Dependency Injection & Service Layer

This document explains the dependency injection pattern and service layer architecture used in the application.

---

## Overview

The application uses a **simple container-based dependency injection** pattern:

1. `DependencyContainer` holds all service instances
2. Services are defined via **protocols** for testability
3. **Mock implementations** enable development without backend
4. **Real implementations** swap in when APIs are ready
5. Container is passed to coordinators, which pass it to ViewFactories

---

## DependencyContainer

**Location:** `Sources/DI/DependencyContainer.swift`

```swift
final class DependencyContainer {

    // MARK: - Service Properties (Lazy Initialization)

    // Secure Storage - declared first (other services may depend on it)
    lazy var secureStorage: SecureStorageProtocol = KeychainSecureStorage()

    // Account Services
    lazy var accountService: AccountServiceProtocol = MockAccountService()

    // Transaction Services
    lazy var transactionService: TransactionServiceProtocol = MockTransactionService()

    // Transfer Services
    lazy var transferService: TransferServiceProtocol = MockTransferService()

    // Card Services
    lazy var cardService: CardServiceProtocol = MockCardService()

    // Beneficiary Services
    lazy var beneficiaryService: BeneficiaryServiceProtocol = MockBeneficiaryService()

    // Notification Services
    lazy var notificationService: NotificationServiceProtocol = MockNotificationService()

    // Biometric Services (real implementation)
    lazy var biometricService: BiometricServiceProtocol = BiometricService()

    // Auth Services
    lazy var authService: AuthServiceProtocol = MockAuthService()

    // MARK: - Initialization

    init() {}
}
```

### Key Characteristics

1. **Lazy Initialization**: Services created on first access, not at app launch
2. **Single Instance**: Each service instantiated once and reused
3. **Protocol Types**: Properties typed as protocols, not concrete classes
4. **Dependency Ordering**: Services declared after their dependencies

---

## Service Protocols

**Location:** `Sources/Services/Protocols/`

Protocols define the contract that all implementations must fulfill:

```swift
// AccountServiceProtocol.swift
protocol AccountServiceProtocol {
    func fetchAccounts() async throws -> [Account]
    func fetchAccount(id: String) async throws -> Account
    func setDefaultAccount(id: String) async throws
}

// TransactionServiceProtocol.swift
protocol TransactionServiceProtocol {
    func fetchTransactions(accountId: String, page: Int, limit: Int) async throws -> TransactionPage
    func fetchTransaction(id: String) async throws -> Transaction
    func searchTransactions(accountId: String, query: String) async throws -> [Transaction]
}

// AuthServiceProtocol.swift
protocol AuthServiceProtocol {
    var isAuthenticatedPublisher: AnyPublisher<Bool, Never> { get }
    var currentUser: User? { get }

    func login(username: String, password: String) async throws -> AuthResult
    func logout() async throws
    func refreshSession() async throws
    func verifyOTP(code: String, reference: String) async throws -> Bool
}
```

### Protocol Design Guidelines

1. **Async/Await**: All network operations use `async throws`
2. **Return Domain Types**: Return models, not raw data
3. **Pagination Support**: List endpoints support page/limit
4. **Publishers for State**: Use Combine for observable state (e.g., auth status)

---

## Mock Implementations

**Location:** `Sources/Services/Implementations/`

Mock services simulate backend behavior for development:

```swift
final class MockAccountService: AccountServiceProtocol {

    // Simulated data
    private let mockAccounts: [Account] = [
        Account(
            id: "ACC001",
            accountNumber: "1234567890",
            accountType: .checking,
            currency: "USD",
            balance: 5432.50,
            availableBalance: 5232.50,
            accountName: "Primary Checking",
            iban: "US12345678901234567890",
            isDefault: true
        ),
        Account(
            id: "ACC002",
            accountNumber: "0987654321",
            accountType: .savings,
            currency: "USD",
            balance: 15000.00,
            availableBalance: 15000.00,
            accountName: "Emergency Savings",
            iban: nil,
            isDefault: false
        )
    ]

    func fetchAccounts() async throws -> [Account] {
        // Simulate network latency
        try await Task.sleep(nanoseconds: 500_000_000)  // 0.5 seconds
        return mockAccounts
    }

    func fetchAccount(id: String) async throws -> Account {
        try await Task.sleep(nanoseconds: 300_000_000)

        guard let account = mockAccounts.first(where: { $0.id == id }) else {
            throw ServiceError.notFound
        }
        return account
    }

    func setDefaultAccount(id: String) async throws {
        try await Task.sleep(nanoseconds: 200_000_000)
        // In real implementation: API call to update default
    }
}
```

### Mock Implementation Guidelines

1. **Realistic Delays**: Use `Task.sleep` to simulate network latency
2. **Realistic Data**: Use plausible banking values and formats
3. **Error Simulation**: Can throw errors to test error handling
4. **Stateful When Needed**: Mocks can track state (e.g., beneficiary list after add)

---

## Real Implementations

Some services have real implementations:

### BiometricService

```swift
final class BiometricService: BiometricServiceProtocol {
    private let context = LAContext()

    func authenticate(reason: String) async throws -> Bool {
        var error: NSError?

        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            throw BiometricError.notAvailable
        }

        return try await context.evaluatePolicy(
            .deviceOwnerAuthenticationWithBiometrics,
            localizedReason: reason
        )
    }

    var biometricType: BiometricType {
        switch context.biometryType {
        case .faceID: return .faceID
        case .touchID: return .touchID
        default: return .none
        }
    }
}
```

### KeychainSecureStorage

```swift
final class KeychainSecureStorage: SecureStorageProtocol {

    func save(_ data: Data, forKey key: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data
        ]

        SecItemDelete(query as CFDictionary)  // Remove existing
        let status = SecItemAdd(query as CFDictionary, nil)

        guard status == errSecSuccess else {
            throw SecureStorageError.saveFailed
        }
    }

    func load(forKey key: String) throws -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess else {
            return nil
        }

        return result as? Data
    }

    func delete(forKey key: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]

        SecItemDelete(query as CFDictionary)
    }
}
```

---

## Injection Flow

### At App Launch

```swift
// BankingApp.swift
@main
struct BankingApp: App {
    @StateObject private var appCoordinator: AppCoordinator

    init() {
        let container = DependencyContainer()
        _appCoordinator = StateObject(wrappedValue: AppCoordinator(dependencyContainer: container))
    }
}
```

### To Coordinators

```swift
// AppCoordinator.swift
init(dependencyContainer: DependencyContainer) {
    self.dependencyContainer = dependencyContainer
    setupChildCoordinators()
}

private func setupChildCoordinators() {
    homeCoordinator = HomeCoordinator(parent: self, dependencyContainer: dependencyContainer)
    accountsCoordinator = AccountsCoordinator(parent: self, dependencyContainer: dependencyContainer)
    // ...
}
```

### To ViewFactories

```swift
// AccountsCoordinator.swift
init(parent: AppCoordinator, dependencyContainer: DependencyContainer) {
    self.parent = parent
    self.dependencyContainer = dependencyContainer
    self.viewFactory = AccountsViewFactory(dependencyContainer: dependencyContainer)
}
```

### To ViewModels

```swift
// AccountsViewFactory.swift
func makeAccountDetailView(accountId: String, coordinator: AccountsCoordinator) -> some View {
    let viewModel = AccountDetailViewModel(
        accountId: accountId,
        accountService: dependencyContainer.accountService,
        transactionService: dependencyContainer.transactionService,
        coordinator: coordinator
    )
    return AccountDetailView(viewModel: viewModel)
}
```

---

## Adding a New Service

### 1. Define Protocol

```swift
// Sources/Services/Protocols/YourServiceProtocol.swift
protocol YourServiceProtocol {
    func fetchItems() async throws -> [YourItem]
    func fetchItem(id: String) async throws -> YourItem
    func createItem(_ item: YourItem) async throws -> YourItem
    func updateItem(_ item: YourItem) async throws
    func deleteItem(id: String) async throws
}
```

### 2. Create Mock Implementation

```swift
// Sources/Services/Implementations/MockYourService.swift
final class MockYourService: YourServiceProtocol {
    private var items: [YourItem] = [
        YourItem(id: "1", name: "Item 1"),
        YourItem(id: "2", name: "Item 2")
    ]

    func fetchItems() async throws -> [YourItem] {
        try await Task.sleep(nanoseconds: 500_000_000)
        return items
    }

    func fetchItem(id: String) async throws -> YourItem {
        try await Task.sleep(nanoseconds: 300_000_000)
        guard let item = items.first(where: { $0.id == id }) else {
            throw ServiceError.notFound
        }
        return item
    }

    func createItem(_ item: YourItem) async throws -> YourItem {
        try await Task.sleep(nanoseconds: 400_000_000)
        items.append(item)
        return item
    }

    func updateItem(_ item: YourItem) async throws {
        try await Task.sleep(nanoseconds: 400_000_000)
        if let index = items.firstIndex(where: { $0.id == item.id }) {
            items[index] = item
        }
    }

    func deleteItem(id: String) async throws {
        try await Task.sleep(nanoseconds: 300_000_000)
        items.removeAll { $0.id == id }
    }
}
```

### 3. Register in DependencyContainer

```swift
// DependencyContainer.swift
lazy var yourService: YourServiceProtocol = MockYourService()
```

### 4. Inject into ViewModels

```swift
// In ViewFactory
let viewModel = YourViewModel(
    service: dependencyContainer.yourService,
    coordinator: coordinator
)
```

---

## Swapping Implementations

When real APIs are ready, swap implementations in DependencyContainer:

```swift
// Development
lazy var accountService: AccountServiceProtocol = MockAccountService()

// Production
lazy var accountService: AccountServiceProtocol = RealAccountService(
    baseURL: Configuration.apiBaseURL,
    authService: authService
)
```

### Environment-Based Configuration

```swift
final class DependencyContainer {
    private let environment: Environment

    init(environment: Environment = .current) {
        self.environment = environment
    }

    lazy var accountService: AccountServiceProtocol = {
        switch environment {
        case .development, .staging:
            return MockAccountService()
        case .production:
            return RealAccountService(baseURL: environment.apiBaseURL)
        }
    }()
}
```

---

## Service Error Handling

Define common service errors:

```swift
enum ServiceError: Error, LocalizedError {
    case notFound
    case unauthorized
    case networkError
    case serverError(Int)
    case decodingError
    case unknown

    var errorDescription: String? {
        switch self {
        case .notFound:
            return "The requested resource was not found."
        case .unauthorized:
            return "You are not authorized to perform this action."
        case .networkError:
            return "A network error occurred. Please check your connection."
        case .serverError(let code):
            return "Server error occurred (code: \(code))."
        case .decodingError:
            return "Unable to process the server response."
        case .unknown:
            return "An unknown error occurred."
        }
    }
}
```

---

## Testing with Mock Services

### Unit Testing ViewModels

```swift
class AccountDetailViewModelTests: XCTestCase {
    var viewModel: AccountDetailViewModel!
    var mockService: MockAccountService!
    var mockCoordinator: MockAccountsCoordinator!

    override func setUp() {
        mockService = MockAccountService()
        mockCoordinator = MockAccountsCoordinator()
        viewModel = AccountDetailViewModel(
            accountId: "ACC001",
            accountService: mockService,
            transactionService: MockTransactionService(),
            coordinator: mockCoordinator
        )
    }

    func testLoadData() async {
        await viewModel.loadData()

        XCTAssertNotNil(viewModel.account)
        XCTAssertEqual(viewModel.account?.id, "ACC001")
        XCTAssertFalse(viewModel.isLoading)
    }
}
```

### Preview Providers

```swift
struct AccountDetailView_Previews: PreviewProvider {
    static var previews: some View {
        let container = DependencyContainer()
        let coordinator = PreviewAccountsCoordinator()
        let viewModel = AccountDetailViewModel(
            accountId: "ACC001",
            accountService: container.accountService,
            transactionService: container.transactionService,
            coordinator: coordinator
        )
        return AccountDetailView(viewModel: viewModel)
    }
}
```

---

## Service Catalog

| Service | Protocol | Mock | Real |
|---------|----------|------|------|
| Accounts | `AccountServiceProtocol` | `MockAccountService` | - |
| Transactions | `TransactionServiceProtocol` | `MockTransactionService` | - |
| Transfers | `TransferServiceProtocol` | `MockTransferService` | - |
| Cards | `CardServiceProtocol` | `MockCardService` | - |
| Beneficiaries | `BeneficiaryServiceProtocol` | `MockBeneficiaryService` | - |
| Notifications | `NotificationServiceProtocol` | `MockNotificationService` | - |
| Auth | `AuthServiceProtocol` | `MockAuthService` | - |
| Biometrics | `BiometricServiceProtocol` | - | `BiometricService` |
| Secure Storage | `SecureStorageProtocol` | - | `KeychainSecureStorage` |

---

## See Also

- [01-architecture-overview.md](01-architecture-overview.md) - Service layer in context
- [04-adding-features.md](04-adding-features.md) - Using services in features
- [05-decisions.md](05-decisions.md) - ADR-004: Mock services decision
