import SwiftUI

struct EmptyStateView: View {
    let iconName: String
    let title: String
    let message: String
    let actionTitle: String?
    let action: (() -> Void)?

    init(
        iconName: String,
        title: String,
        message: String,
        actionTitle: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.iconName = iconName
        self.title = title
        self.message = message
        self.actionTitle = actionTitle
        self.action = action
    }

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: iconName)
                .font(.system(size: 56))
                .foregroundColor(.secondary)
                .padding(.bottom, 8)

            Text(title)
                .font(.headline)
                .foregroundColor(.primary)

            Text(message)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            if let actionTitle = actionTitle, let action = action {
                Button(action: action) {
                    Text(actionTitle)
                        .font(.headline)
                        .frame(height: 50)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .padding(.top, 8)
            }
        }
        .padding()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title). \(message)")
    }
}

// MARK: - Preview

#Preview("EmptyStateView - No Action") {
    EmptyStateView(
        iconName: "wallet.pass",
        title: "No Accounts",
        message: "You don't have any accounts yet."
    )
}

#Preview("EmptyStateView - With Action") {
    EmptyStateView(
        iconName: "creditcard",
        title: "No Cards",
        message: "You don't have any cards associated with your account.",
        actionTitle: "Request Card",
        action: {
            print("Request card tapped")
        }
    )
}

#Preview("EmptyStateView - Transactions") {
    EmptyStateView(
        iconName: "list.bullet.rectangle",
        title: "No Transactions",
        message: "No transactions found for the selected filters."
    )
}
