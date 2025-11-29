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

// MARK: - Preview

#Preview("ActionButton - States") {
    VStack(spacing: 20) {
        Text("Button States")
            .font(.title2)
            .fontWeight(.bold)

        ActionButton(
            title: "Normal State",
            action: {
                print("Normal button tapped")
            }
        )

        ActionButton(
            title: "Loading State",
            isLoading: true,
            action: {}
        )

        ActionButton(
            title: "Disabled State",
            isDisabled: true,
            action: {}
        )

        ActionButton(
            title: "Long Button Title Text",
            action: {
                print("Long title button tapped")
            }
        )
    }
    .padding()
}

#Preview("ActionButton - Interactive") {
    struct PreviewWrapper: View {
        @State private var isLoading = false
        @State private var isDisabled = false

        var body: some View {
            VStack(spacing: 20) {
                ActionButton(
                    title: "Submit",
                    isLoading: isLoading,
                    isDisabled: isDisabled,
                    action: {
                        isLoading = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            isLoading = false
                        }
                    }
                )

                Toggle("Loading", isOn: $isLoading)
                Toggle("Disabled", isOn: $isDisabled)
            }
            .padding()
        }
    }

    return PreviewWrapper()
}
