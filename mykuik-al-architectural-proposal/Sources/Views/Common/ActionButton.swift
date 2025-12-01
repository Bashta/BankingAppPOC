import SwiftUI

struct ActionButton: View {
    let title: String
    let isLoading: Bool
    let isDisabled: Bool
    let action: () -> Void

    init(
        title: String,
        isLoading: Bool = false,
        isDisabled: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.isLoading = isLoading
        self.isDisabled = isDisabled
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            ZStack {
                // Hidden text to maintain button height
                Text(title)
                    .font(.headline)
                    .opacity(isLoading ? 0 : 1)

                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                }
            }
            .frame(height: 50)
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .disabled(isDisabled || isLoading)
        .opacity(isDisabled && !isLoading ? 0.6 : 1.0)
        .accessibilityLabel(title)
        .accessibilityHint(isDisabled ? "Button is disabled" : "")
        .accessibilityValue(isLoading ? "Loading" : "")
    }
}
