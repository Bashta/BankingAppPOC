# Code Conventions

This document outlines the coding conventions, patterns, and best practices used throughout the codebase.

---

## File Naming

| Component | Pattern | Example |
|-----------|---------|---------|
| Model | `{Name}.swift` | `Account.swift` |
| View | `{Name}View.swift` | `AccountDetailView.swift` |
| ViewModel | `{Name}ViewModel.swift` | `AccountDetailViewModel.swift` |
| Coordinator | `{Feature}Coordinator.swift` | `AccountsCoordinator.swift` |
| ViewFactory | `{Feature}ViewFactory.swift` | `AccountsViewFactory.swift` |
| Service Protocol | `{Name}ServiceProtocol.swift` | `AccountServiceProtocol.swift` |
| Mock Service | `Mock{Name}Service.swift` | `MockAccountService.swift` |
| Route | `Routes.swift` (all in one file) | - |

---

## Type Naming

### Classes & Structs

```swift
// Models - Structs (value semantics)
struct Account { }
struct Transaction { }

// ViewModels - Classes (reference semantics, ObservableObject)
final class AccountDetailViewModel: ObservableObject { }

// Coordinators - Classes (reference semantics, ObservableObject)
final class AccountsCoordinator: ObservableObject { }

// Services - Classes (stateful, reference semantics)
final class MockAccountService: AccountServiceProtocol { }
```

### Enums

```swift
// Route enums - PascalCase
enum AccountsRoute: Route {
    case list
    case detail(accountId: String)
}

// State enums
enum LoadingState {
    case idle
    case loading
    case loaded
    case error(Error)
}

// Type enums in models
enum AccountType: String, Codable {
    case checking
    case savings
    case credit
}
```

### Protocols

```swift
// Service protocols end with "Protocol"
protocol AccountServiceProtocol { }

// Route protocol
protocol Route: Hashable, Identifiable { }
```

---

## Property Naming

### Published Properties

```swift
final class AccountDetailViewModel: ObservableObject {
    // Data
    @Published var account: Account?
    @Published var transactions: [Transaction] = []

    // Loading states
    @Published var isLoading = false
    @Published var isRefreshing = false

    // Error state
    @Published var error: Error?

    // UI toggles
    @Published var showBalance = true
}
```

### Private Properties

```swift
// Dependencies - private, not published
private let accountService: AccountServiceProtocol
private let transactionService: TransactionServiceProtocol

// Coordinator - weak to prevent retain cycle
weak var coordinator: AccountsCoordinator?

// Constants
let accountId: String
```

---

## Method Naming

### Data Loading

```swift
// Initial load
@MainActor
func loadData() async { }

// Pull-to-refresh
@MainActor
func refresh() async { }

// Pagination
@MainActor
func loadMore() async { }

// Search
@MainActor
func search(query: String) async { }
```

### Navigation

```swift
// Show detail
func showAccountDetail(_ account: Account) { }
func showTransactionDetail(_ transaction: Transaction) { }

// Generic navigation
func showSettings() { }
func showHelp() { }

// Go back
func goBack() { }
func dismiss() { }
```

### Actions

```swift
// User actions - verb form
func saveChanges() async { }
func deleteItem() async { }
func confirmTransfer() async { }

// Toggle actions
func toggleBalanceVisibility() { }
func toggleNotifications() { }
```

---

## MARK Comments

Organize files with consistent MARK sections:

```swift
final class AccountDetailViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published var account: Account?

    // MARK: - Properties

    let accountId: String

    // MARK: - Dependencies

    private let accountService: AccountServiceProtocol
    weak var coordinator: AccountsCoordinator?

    // MARK: - Initialization

    init(...) { }

    // MARK: - Public Methods

    @MainActor
    func loadData() async { }

    // MARK: - Navigation

    func showTransactions() { }

    // MARK: - Private Methods

    private func processData() { }
}
```

---

## ViewModel Pattern

### Standard Structure

```swift
final class YourViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published var data: YourData?
    @Published var items: [Item] = []
    @Published var isLoading = false
    @Published var isRefreshing = false
    @Published var error: Error?

    // MARK: - Properties

    let itemId: String

    // MARK: - Dependencies

    private let service: YourServiceProtocol
    weak var coordinator: YourCoordinator?

    // MARK: - Initialization

    init(
        itemId: String,
        service: YourServiceProtocol,
        coordinator: YourCoordinator?
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
            data = try await service.fetchData(id: itemId)
            Logger.feature.debug("Loaded data for \(self.itemId)")
        } catch {
            self.error = error
            Logger.feature.error("Failed: \(error.localizedDescription)")
        }
    }

    @MainActor
    func refresh() async {
        isRefreshing = true
        defer { isRefreshing = false }

        do {
            data = try await service.fetchData(id: itemId)
            error = nil
        } catch {
            self.error = error
        }
    }

    // MARK: - Navigation

    func showDetail() {
        coordinator?.push(.detail(itemId: itemId))
    }

    func goBack() {
        coordinator?.pop()
    }
}
```

---

## View Pattern

### Standard Structure

```swift
struct YourView: View {
    @ObservedObject var viewModel: YourViewModel

    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.data == nil {
                LoadingView()
            } else if let data = viewModel.data {
                content(data: data)
            } else if viewModel.error != nil {
                ErrorView(
                    message: "Unable to load data",
                    retryAction: { Task { await viewModel.loadData() } }
                )
            } else {
                EmptyStateView(
                    title: "No Data",
                    message: "Nothing to display"
                )
            }
        }
        .navigationTitle("Title")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.loadData()
        }
        .refreshable {
            await viewModel.refresh()
        }
    }

    @ViewBuilder
    private func content(data: YourData) -> some View {
        ScrollView {
            VStack(spacing: 16) {
                // UI components
            }
            .padding()
        }
    }
}
```

### State Handling

Always handle these states:
1. **Loading** - Initial data fetch
2. **Content** - Data loaded successfully
3. **Error** - Data fetch failed
4. **Empty** - Data loaded but empty

---

## Logging

### Use Logger, Never print()

```swift
import OSLog

// Available loggers
Logger.auth       // Authentication
Logger.accounts   // Account operations
Logger.transfer   // Transfer operations
Logger.cards      // Card operations
Logger.more       // Profile/settings
Logger.home       // Dashboard/notifications
Logger.navigation // Navigation events
Logger.services   // Service layer
Logger.deepLink   // Deep link parsing
Logger.biometric  // Biometric auth
```

### Log Levels

```swift
// Debug - detailed info for debugging (not persisted)
Logger.accounts.debug("Loaded \(accounts.count) accounts")

// Info - general information
Logger.auth.info("User logged in successfully")

// Error - error conditions (persisted)
Logger.transfer.error("Transfer failed: \(error.localizedDescription)")

// Fault - critical failures
Logger.auth.fault("Session corruption detected")
```

### Logging Guidelines

```swift
// DO: Log meaningful events
Logger.accounts.debug("Loaded account \(accountId) with balance \(balance)")

// DON'T: Use print
print("Account loaded")  // NEVER

// DO: Include context in errors
Logger.transfer.error("Transfer \(transferId) failed: \(error.localizedDescription)")

// DON'T: Log sensitive data
Logger.auth.debug("Password: \(password)")  // NEVER
```

---

## Sensitive Data Masking

### Account Numbers

```swift
extension String {
    var maskedAccountNumber: String {
        guard count > 4 else { return self }
        let lastFour = suffix(4)
        return "****\(lastFour)"
    }
}

// Usage
Text(account.accountNumber.maskedAccountNumber)  // "****7890"
```

### Card Numbers

```swift
extension String {
    var maskedCardNumber: String {
        guard count >= 4 else { return self }
        let lastFour = suffix(4)
        return "**** **** **** \(lastFour)"
    }
}

// Usage
Text(card.cardNumber.maskedCardNumber)  // "**** **** **** 3456"
```

### Display Rules

| Data Type | Display Format | Example |
|-----------|----------------|---------|
| Account Number | `****{last4}` | `****7890` |
| Card Number | `**** **** **** {last4}` | `**** **** **** 3456` |
| IBAN | Show full (public identifier) | `US12345678901234567890` |
| CVV | Never display | - |
| PIN | Never display | - |

---

## Currency Formatting

```swift
extension Decimal {
    func formatted(currency: String) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency
        return formatter.string(from: self as NSDecimalNumber) ?? "\(currency) \(self)"
    }
}

// Usage
Text(account.balance.formatted(currency: account.currency))  // "$5,432.50"
```

---

## Transaction Display

### Amount Colors

```swift
extension TransactionType {
    var amountColor: Color {
        switch self {
        case .credit: return .green   // Money in
        case .debit: return .primary  // Money out
        }
    }

    var amountPrefix: String {
        switch self {
        case .credit: return "+"
        case .debit: return "-"
        }
    }
}

// Usage
Text("\(transaction.type.amountPrefix)\(transaction.amount.formatted(currency: transaction.currency))")
    .foregroundColor(transaction.type.amountColor)
// "+$100.00" in green or "-$50.00" in primary color
```

### Category Icons

```swift
extension TransactionCategory {
    var icon: String {
        switch self {
        case .transfer: return "arrow.left.arrow.right"
        case .payment: return "creditcard"
        case .withdrawal: return "banknote"
        case .deposit: return "arrow.down.to.line"
        case .purchase: return "cart"
        case .salary: return "briefcase"
        // ...
        }
    }
}

// Usage
Image(systemName: transaction.category.icon)
```

---

## Date Formatting

```swift
extension Date {
    var relativeFormatted: String {
        let calendar = Calendar.current

        if calendar.isDateInToday(self) {
            let formatter = DateFormatter()
            formatter.dateFormat = "h:mm a"
            return "Today, \(formatter.string(from: self))"
        } else if calendar.isDateInYesterday(self) {
            return "Yesterday"
        } else if let weekAgo = calendar.date(byAdding: .day, value: -7, to: Date()),
                  self > weekAgo {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE"
            return formatter.string(from: self)
        } else {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            return formatter.string(from: self)
        }
    }

    func fullDateTimeString() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .short
        return formatter.string(from: self)
    }
}

// Usage
Text(transaction.date.relativeFormatted)  // "Today, 2:30 PM" or "Monday" or "Nov 15, 2024"
```

---

## Error Handling

### In ViewModels

```swift
@MainActor
func loadData() async {
    isLoading = true
    error = nil
    defer { isLoading = false }

    do {
        data = try await service.fetchData()
    } catch {
        self.error = error
        Logger.feature.error("Load failed: \(error.localizedDescription)")
    }
}
```

### In Views

```swift
if viewModel.error != nil {
    ErrorView(
        message: "Unable to load data",
        retryAction: { Task { await viewModel.loadData() } }
    )
}
```

### Service Errors

```swift
enum ServiceError: Error, LocalizedError {
    case notFound
    case unauthorized
    case networkError
    case serverError(Int)

    var errorDescription: String? {
        switch self {
        case .notFound: return "Resource not found"
        case .unauthorized: return "Not authorized"
        case .networkError: return "Network error"
        case .serverError(let code): return "Server error (\(code))"
        }
    }
}
```

---

## Pull-to-Refresh

Always implement on data views:

```swift
struct ListView: View {
    @ObservedObject var viewModel: ListViewModel

    var body: some View {
        List {
            // Content
        }
        .refreshable {
            await viewModel.refresh()
        }
    }
}
```

---

## Async/Await

### MainActor for UI Updates

```swift
@MainActor
func loadData() async {
    isLoading = true
    // ... async work
    isLoading = false  // UI update on main thread
}
```

### Parallel Loading

```swift
@MainActor
func loadData() async {
    do {
        async let accountTask = accountService.fetchAccount(id: accountId)
        async let transactionsTask = transactionService.fetchTransactions(accountId: accountId)

        let (account, transactions) = try await (accountTask, transactionsTask)
        self.account = account
        self.transactions = transactions
    } catch {
        self.error = error
    }
}
```

---

## SwiftUI Modifiers Order

Consistent modifier ordering:

```swift
Text("Hello")
    // 1. Content modifiers
    .font(.title)
    .foregroundColor(.primary)

    // 2. Layout modifiers
    .frame(maxWidth: .infinity)
    .padding()

    // 3. Background/overlay
    .background(Color.gray.opacity(0.1))
    .cornerRadius(8)

    // 4. Interaction
    .onTapGesture { }

    // 5. Navigation
    .navigationTitle("Title")
    .navigationBarTitleDisplayMode(.inline)

    // 6. Lifecycle
    .task { }
    .onAppear { }

    // 7. Sheets/alerts
    .sheet(isPresented: $showSheet) { }
    .alert(isPresented: $showAlert) { }
```

---

## See Also

- [01-architecture-overview.md](01-architecture-overview.md) - Code organization
- [04-adding-features.md](04-adding-features.md) - Applying conventions
- [05-decisions.md](05-decisions.md) - ADR-009: Logging decision
