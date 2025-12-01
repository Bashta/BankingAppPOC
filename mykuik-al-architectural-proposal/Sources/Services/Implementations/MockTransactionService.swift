import Foundation

final class MockTransactionService: TransactionServiceProtocol {
    private var transactionsByAccount: [String: [Transaction]] = [:]

    private let accountNames: [String: String] = [
        "ACC001": "Primary Checking",
        "ACC002": "Emergency Savings",
        "ACC003": "Investment Account",
        "ACC004": "Daily Expenses"
    ]

    init() {
        // Generate realistic transactions for each account
        let accountIds = ["ACC001", "ACC002", "ACC003", "ACC004"]

        for accountId in accountIds {
            transactionsByAccount[accountId] = generateTransactions(for: accountId)
        }
    }

    private func generateTransactions(for accountId: String) -> [Transaction] {
        let accountName = accountNames[accountId]
        let startingBalance: Decimal = accountId == "ACC001" ? 5432.50 : (accountId == "ACC002" ? 15000.00 : (accountId == "ACC003" ? 25000.00 : 892.35))
        var balance = startingBalance
        var transactions: [Transaction] = []

        let transactionData: [(description: String, merchant: String?, amount: Decimal, category: TransactionCategory, daysAgo: Int)] = [
            ("Amazon Purchase", "Amazon", -45.99, .purchase, 1),
            ("Starbucks Coffee", "Starbucks", -12.50, .purchase, 2),
            ("Salary Deposit", nil, 3500.00, .salary, 3),
            ("Walmart Groceries", "Walmart", -125.80, .purchase, 5),
            ("ATM Withdrawal", nil, -200.00, .withdrawal, 7),
            ("Utility Bill Payment", "Electric Co", -89.50, .transfer, 10),
            ("Amazon Refund", "Amazon", 45.99, .refund, 12),
            ("Restaurant Dinner", "The Steakhouse", -85.00, .purchase, 14),
            ("Gas Station", "Shell", -45.00, .purchase, 15),
            ("Monthly Fee", nil, -12.00, .fee, 16),
            ("Transfer from Savings", nil, 500.00, .transfer, 18),
            ("Netflix Subscription", "Netflix", -15.99, .purchase, 20),
            ("Pharmacy Purchase", "CVS", -35.20, .purchase, 22),
            ("Gym Membership", "Fitness Plus", -49.99, .purchase, 25),
            ("Salary Deposit", nil, 3500.00, .salary, 33),
            ("Coffee Shop", "Starbucks", -8.75, .purchase, 35),
            ("Uber Ride", "Uber", -22.50, .purchase, 40),
            ("Grocery Store", "Whole Foods", -145.60, .purchase, 42),
            ("Online Shopping", "Amazon", -89.99, .purchase, 45),
            ("Deposit Check", nil, 250.00, .deposit, 50),
            ("Restaurant Lunch", "Thai Kitchen", -28.50, .purchase, 52),
            ("Gas Station", "Chevron", -50.00, .purchase, 55),
            ("Transfer to Checking", nil, -300.00, .transfer, 60),
            ("Interest Credit", nil, 5.25, .salary, 65),
        ]

        for (index, data) in transactionData.enumerated() {
            let transaction = Transaction(
                id: "TXN\(String(format: "%06d", index + 1))",
                accountId: accountId,
                accountName: accountName,
                type: data.amount > 0 ? .credit : .debit,
                amount: abs(data.amount),
                currency: "USD",
                description: data.description,
                merchantName: data.merchant,
                category: data.category,
                date: Date().addingTimeInterval(-Double(data.daysAgo) * 86400),
                status: .completed,
                reference: "REF\(String(format: "%08d", index + 1))",
                balance: balance
            )
            transactions.append(transaction)
            balance -= data.amount
        }

        // Sort by date descending (newest first)
        return transactions.sorted { $0.date > $1.date }
    }

    func fetchTransactions(accountId: String, page: Int, limit: Int) async throws -> TransactionPage {
        try await Task.sleep(nanoseconds: UInt64.random(in: 300_000_000...500_000_000))

        guard let allTransactions = transactionsByAccount[accountId] else {
            return TransactionPage(transactions: [], currentPage: page, totalPages: 0, totalItems: 0)
        }

        let totalItems = allTransactions.count
        let totalPages = (totalItems + limit - 1) / limit
        let startIndex = (page - 1) * limit
        let endIndex = min(startIndex + limit, totalItems)

        guard startIndex < totalItems else {
            return TransactionPage(transactions: [], currentPage: page, totalPages: totalPages, totalItems: totalItems)
        }

        let pageTransactions = Array(allTransactions[startIndex..<endIndex])

        return TransactionPage(
            transactions: pageTransactions,
            currentPage: page,
            totalPages: totalPages,
            totalItems: totalItems
        )
    }

    func fetchTransaction(id: String) async throws -> Transaction {
        try await Task.sleep(nanoseconds: UInt64.random(in: 300_000_000...500_000_000))

        for transactions in transactionsByAccount.values {
            if let transaction = transactions.first(where: { $0.id == id }) {
                return transaction
            }
        }

        throw TransactionError.transactionNotFound
    }

    func searchTransactions(accountId: String, query: String) async throws -> [Transaction] {
        try await Task.sleep(nanoseconds: UInt64.random(in: 300_000_000...500_000_000))

        guard let allTransactions = transactionsByAccount[accountId] else {
            return []
        }

        let lowercasedQuery = query.lowercased()

        return allTransactions.filter { transaction in
            transaction.description.lowercased().contains(lowercasedQuery) ||
            (transaction.merchantName?.lowercased().contains(lowercasedQuery) ?? false)
        }
    }

    func filterTransactions(accountId: String, dateRange: (Date, Date)?, categories: Set<TransactionCategory>) async throws -> [Transaction] {
        try await Task.sleep(nanoseconds: UInt64.random(in: 300_000_000...500_000_000))

        guard let allTransactions = transactionsByAccount[accountId] else {
            return []
        }

        var filteredTransactions = allTransactions

        // Filter by date range if provided
        if let (startDate, endDate) = dateRange {
            filteredTransactions = filteredTransactions.filter { transaction in
                transaction.date >= startDate && transaction.date <= endDate
            }
        }

        // Filter by categories if not empty
        if !categories.isEmpty {
            filteredTransactions = filteredTransactions.filter { transaction in
                categories.contains(transaction.category)
            }
        }

        return filteredTransactions
    }

    func fetchRecentTransactions(limit: Int) async throws -> [Transaction] {
        try await Task.sleep(nanoseconds: UInt64.random(in: 300_000_000...500_000_000))

        // Collect all transactions from all accounts
        var allTransactions: [Transaction] = []
        for transactions in transactionsByAccount.values {
            allTransactions.append(contentsOf: transactions)
        }

        // Sort by date descending (newest first) and take limit
        return allTransactions
            .sorted { $0.date > $1.date }
            .prefix(limit)
            .map { $0 }
    }
}

enum TransactionError: Error {
    case transactionNotFound
    case invalidDateRange
}
