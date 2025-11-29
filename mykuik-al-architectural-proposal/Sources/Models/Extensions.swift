import Foundation
import SwiftUI

// MARK: - String Extensions

extension String {
    /// Masks account number, showing only the last 4 digits
    /// Example: "1234567890" → "****7890"
    var maskedAccountNumber: String {
        guard count > 4 else { return self }
        let lastFour = suffix(4)
        return "****\(lastFour)"
    }

    /// Masks card number, showing only the last 4 digits with formatting
    /// Example: "1234567890123456" → "**** **** **** 3456"
    var maskedCardNumber: String {
        guard count >= 4 else { return self }
        let lastFour = suffix(4)
        return "**** **** **** \(lastFour)"
    }
}

// MARK: - Decimal Extensions

extension Decimal {
    /// Formats decimal as currency with proper locale formatting
    /// Example: Decimal(1234.56).formatted(currency: "USD") → "$1,234.56"
    func formatted(currency: String) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency
        return formatter.string(from: self as NSDecimalNumber) ?? "\(currency) \(self)"
    }
}

// MARK: - TransactionType Extensions

extension TransactionType {
    /// Color for transaction amount based on type
    /// Credit: green (money in), Debit: primary (money out)
    var amountColor: Color {
        switch self {
        case .credit:
            return .green
        case .debit:
            return .primary
        }
    }

    /// Prefix for transaction amount display
    /// Credit: "+", Debit: "-"
    var amountPrefix: String {
        switch self {
        case .credit:
            return "+"
        case .debit:
            return "-"
        }
    }
}

// MARK: - TransactionCategory Extensions

extension TransactionCategory {
    /// SF Symbol icon for transaction category
    var icon: String {
        switch self {
        case .transfer:
            return "arrow.left.arrow.right"
        case .payment:
            return "creditcard"
        case .withdrawal:
            return "banknote"
        case .deposit:
            return "arrow.down.to.line"
        case .fee:
            return "percent"
        case .interest:
            return "chart.line.uptrend.xyaxis"
        case .purchase:
            return "cart"
        case .refund:
            return "arrow.uturn.backward"
        case .salary:
            return "briefcase"
        case .other:
            return "questionmark.circle"
        }
    }
}

// MARK: - Date Extensions

extension Date {
    /// Formats date as relative string for recent transactions
    /// Today: "Today, 2:30 PM"
    /// Yesterday: "Yesterday"
    /// This week: "Monday"
    /// Older: "Nov 15, 2024"
    var relativeFormatted: String {
        let calendar = Calendar.current
        let now = Date()

        if calendar.isDateInToday(self) {
            let formatter = DateFormatter()
            formatter.dateFormat = "h:mm a"
            return "Today, \(formatter.string(from: self))"
        } else if calendar.isDateInYesterday(self) {
            return "Yesterday"
        } else if let weekAgo = calendar.date(byAdding: .day, value: -7, to: now),
                  self > weekAgo {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE"
            return formatter.string(from: self)
        } else {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .none
            return formatter.string(from: self)
        }
    }
}
