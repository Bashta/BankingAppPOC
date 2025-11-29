import SwiftUI

struct AmountInputView: View {
    @Binding var amount: Decimal
    let currency: String
    let minimumAmount: Decimal?
    let maximumAmount: Decimal?

    @State private var amountText: String = ""
    @FocusState private var isFocused: Bool

    init(
        amount: Binding<Decimal>,
        currency: String,
        minimumAmount: Decimal? = nil,
        maximumAmount: Decimal? = nil
    ) {
        self._amount = amount
        self.currency = currency
        self.minimumAmount = minimumAmount
        self.maximumAmount = maximumAmount
    }

    var body: some View {
        VStack(spacing: 8) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(currencySymbol)
                    .font(.title)
                    .foregroundColor(.secondary)

                TextField("0.00", text: $amountText)
                    .font(.system(size: 34, weight: .semibold))
                    .keyboardType(.decimalPad)
                    .focused($isFocused)
                    .multilineTextAlignment(.leading)
                    .onChange(of: amountText) { newValue in
                        updateAmount(from: newValue)
                    }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)

            // Validation hints
            if let validationMessage = validationMessage {
                HStack {
                    Image(systemName: "exclamationmark.circle.fill")
                        .font(.caption)
                    Text(validationMessage)
                        .font(.caption)
                }
                .foregroundColor(.red)
            }
        }
        .onAppear {
            // Initialize text from amount
            if amount > 0 {
                amountText = formattedAmountString(amount)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Amount input")
        .accessibilityValue("Amount \(amount.formatted(currency: currency))")
    }

    private var currencySymbol: String {
        switch currency {
        case "USD": return "$"
        case "EUR": return "€"
        case "GBP": return "£"
        case "JPY": return "¥"
        default: return currency
        }
    }

    private var validationMessage: String? {
        if let min = minimumAmount, amount > 0, amount < min {
            return "Minimum amount is \(min.formatted(currency: currency))"
        }
        if let max = maximumAmount, amount > max {
            return "Maximum amount is \(max.formatted(currency: currency))"
        }
        return nil
    }

    private func updateAmount(from text: String) {
        // Remove non-numeric characters except decimal point
        let filtered = text.filter { $0.isNumber || $0 == "." }

        // Limit to one decimal point
        let components = filtered.components(separatedBy: ".")
        var cleanedText = components[0]
        if components.count > 1 {
            cleanedText += "." + components[1]
        }

        // Limit decimal places to 2
        if let decimalIndex = cleanedText.firstIndex(of: ".") {
            let afterDecimal = cleanedText[cleanedText.index(after: decimalIndex)...]
            if afterDecimal.count > 2 {
                cleanedText = String(cleanedText.prefix(cleanedText.count - (afterDecimal.count - 2)))
            }
        }

        // Update the text field
        if cleanedText != text {
            amountText = cleanedText
        }

        // Convert to Decimal
        if let decimal = Decimal(string: cleanedText), decimal >= 0 {
            amount = decimal
        } else if cleanedText.isEmpty {
            amount = 0
        }
    }

    private func formattedAmountString(_ decimal: Decimal) -> String {
        let nsDecimal = decimal as NSDecimalNumber
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 2
        return formatter.string(from: nsDecimal) ?? "0"
    }
}

// MARK: - Preview

#Preview("AmountInputView - Basic") {
    struct PreviewWrapper: View {
        @State private var amount: Decimal = 0

        var body: some View {
            VStack(spacing: 20) {
                Text("Transfer Amount")
                    .font(.headline)

                AmountInputView(
                    amount: $amount,
                    currency: "USD"
                )

                Text("Amount: \(amount.formatted(currency: "USD"))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
        }
    }

    return PreviewWrapper()
}

#Preview("AmountInputView - With Limits") {
    struct PreviewWrapper: View {
        @State private var amount: Decimal = 50

        var body: some View {
            VStack(spacing: 20) {
                Text("Transfer Amount")
                    .font(.headline)

                AmountInputView(
                    amount: $amount,
                    currency: "USD",
                    minimumAmount: 10.00,
                    maximumAmount: 5000.00
                )

                VStack(spacing: 8) {
                    Text("Current: \(amount.formatted(currency: "USD"))")
                    Text("Min: $10.00, Max: $5,000.00")
                        .font(.caption2)
                }
                .font(.caption)
                .foregroundColor(.secondary)

                HStack {
                    Button("Set $5") { amount = 5 }
                    Button("Set $50") { amount = 50 }
                    Button("Set $6000") { amount = 6000 }
                }
            }
            .padding()
        }
    }

    return PreviewWrapper()
}
