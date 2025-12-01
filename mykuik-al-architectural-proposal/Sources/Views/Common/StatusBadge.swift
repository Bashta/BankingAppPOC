import SwiftUI

// MARK: - StatusBadge

/// A reusable pill-shaped badge for displaying status indicators.
/// Supports CardStatus and can be extended for other status types.
struct StatusBadge: View {
    let text: String
    let color: Color

    var body: some View {
        Text(text)
            .font(.caption2)
            .fontWeight(.semibold)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color)
            .foregroundColor(.white)
            .cornerRadius(8)
    }
}

// MARK: - StatusBadge + CardStatus

extension StatusBadge {
    /// Creates a StatusBadge from a CardStatus
    /// - Parameter status: The card status to display
    init(cardStatus status: CardStatus) {
        self.text = status.displayName
        self.color = status.badgeColor
    }
}

// MARK: - CardStatus Extensions

extension CardStatus {
    /// Display name for the status badge
    var displayName: String {
        switch self {
        case .active:
            return "Active"
        case .inactive:
            return "Inactive"
        case .blocked:
            return "Blocked"
        case .pendingActivation, .pending:
            return "Pending"
        case .expired:
            return "Expired"
        case .cancelled:
            return "Cancelled"
        }
    }

    /// Background color for the status badge
    var badgeColor: Color {
        switch self {
        case .active:
            return .green
        case .blocked:
            return .red
        case .pendingActivation, .pending:
            return .orange
        case .inactive, .expired, .cancelled:
            return .gray
        }
    }
}

// MARK: - Previews

#if DEBUG
struct StatusBadge_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 16) {
            StatusBadge(cardStatus: .active)
            StatusBadge(cardStatus: .blocked)
            StatusBadge(cardStatus: .pending)
            StatusBadge(cardStatus: .expired)
            StatusBadge(cardStatus: .cancelled)
            StatusBadge(text: "Custom", color: .purple)
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
#endif
