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
