import SwiftUI

// MARK: - CardView

/// Visual card representation component with brand logo, masked number, expiry, and status.
/// Displays a gradient background based on card type.
struct CardView: View {
    let card: Card

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header: Brand logo + Status Badge
            HStack {
                brandLogo
                Spacer()
                StatusBadge(cardStatus: card.status)
            }

            Spacer()

            // Card Number (masked)
            Text(card.cardNumber.maskedCardNumber)
                .font(.title2)
                .fontWeight(.medium)
                .tracking(2)
                .foregroundColor(.white)

            // Expiry and Card Type
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("VALID THRU")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.7))
                    Text(formattedExpiry)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                }

                Spacer()

                Text(card.cardType.displayName.uppercased())
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.white.opacity(0.8))
            }

            // Card Holder Name
            Text(card.cardholderName.uppercased())
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.white.opacity(0.9))
        }
        .padding(20)
        .frame(height: 200)
        .background(cardGradient)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
    }

    // MARK: - Private Views

    private var brandLogo: some View {
        HStack(spacing: 4) {
            Image(systemName: "creditcard.fill")
                .font(.title3)
            Text(card.cardBrand.displayName.uppercased())
                .font(.headline)
                .fontWeight(.bold)
        }
        .foregroundColor(.white)
    }

    // MARK: - Private Computed Properties

    private var formattedExpiry: String {
        let month = String(format: "%02d", card.expiryMonth)
        let year = String(card.expiryYear % 100)
        return "\(month)/\(year)"
    }

    private var cardGradient: LinearGradient {
        switch card.cardType {
        case .debit:
            return LinearGradient(
                colors: [Color.blue, Color.blue.opacity(0.7)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .credit:
            return LinearGradient(
                colors: [Color.yellow, Color.orange],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .prepaid:
            return LinearGradient(
                colors: [Color.green, Color.green.opacity(0.7)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
}

// MARK: - CardType Extension

extension CardType {
    var displayName: String {
        switch self {
        case .debit:
            return "Debit"
        case .credit:
            return "Credit"
        case .prepaid:
            return "Prepaid"
        }
    }
}

// MARK: - CardBrand Extension

extension CardBrand {
    var displayName: String {
        switch self {
        case .visa:
            return "Visa"
        case .mastercard:
            return "Mastercard"
        case .amex:
            return "Amex"
        }
    }
}

// MARK: - Previews

#if DEBUG
struct CardView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            // Debit Card (Blue)
            CardView(card: Card(
                id: "1",
                accountId: "ACC1",
                cardNumber: "4532123456781234",
                cardType: .debit,
                cardBrand: .visa,
                cardholderName: "JOHN DOE",
                expiryMonth: 12,
                expiryYear: 2027,
                cvv: "123",
                status: .active,
                limits: CardLimits(dailyPurchase: 5000, dailyWithdrawal: 2000, onlineTransaction: 3000, contactless: 500),
                activatedDate: Date(),
                blockedDate: nil,
                blockReason: nil
            ))

            // Credit Card (Gold)
            CardView(card: Card(
                id: "2",
                accountId: "ACC1",
                cardNumber: "5412345678901234",
                cardType: .credit,
                cardBrand: .mastercard,
                cardholderName: "JOHN DOE",
                expiryMonth: 8,
                expiryYear: 2026,
                cvv: "456",
                status: .blocked,
                limits: CardLimits(dailyPurchase: 10000, dailyWithdrawal: 1000, onlineTransaction: 5000, contactless: 300),
                activatedDate: Date(),
                blockedDate: Date(),
                blockReason: .suspicious
            ))

            // Prepaid Card (Green)
            CardView(card: Card(
                id: "3",
                accountId: "ACC2",
                cardNumber: "4916123456789012",
                cardType: .prepaid,
                cardBrand: .visa,
                cardholderName: "JOHN DOE",
                expiryMonth: 3,
                expiryYear: 2028,
                cvv: "789",
                status: .pending,
                limits: CardLimits(dailyPurchase: 1000, dailyWithdrawal: 500, onlineTransaction: 800, contactless: 100),
                activatedDate: nil,
                blockedDate: nil,
                blockReason: nil
            ))
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
#endif
