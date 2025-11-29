import SwiftUI

struct LoadingView: View {
    let message: String?

    init(message: String? = nil) {
        self.message = message
    }

    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)

            if let message = message {
                Text(message)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .accessibilityLabel("Loading")
    }
}

// MARK: - Preview

#Preview("LoadingView - No Message") {
    LoadingView(message: nil)
}

#Preview("LoadingView - With Message") {
    LoadingView(message: "Loading accounts...")
}

#Preview("LoadingView - Long Message") {
    LoadingView(message: "Please wait while we securely fetch your transaction history...")
        .padding()
}
