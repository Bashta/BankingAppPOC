import SwiftUI

struct ErrorView: View {
    let message: String
    let retryAction: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "xmark.octagon")
                .font(.system(size: 48))
                .foregroundColor(.red)
                .accessibilityLabel("Error")

            Text(message)
                .font(.body)
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            Button(action: retryAction) {
                Text("Retry")
                    .font(.headline)
                    .frame(height: 50)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .accessibilityLabel("Retry button")
        }
        .padding()
    }
}

// MARK: - Preview

#Preview("ErrorView") {
    ErrorView(
        message: "Unable to load accounts. Please check your internet connection and try again.",
        retryAction: {
            print("Retry tapped")
        }
    )
}

#Preview("ErrorView - Short Message") {
    ErrorView(
        message: "Network error",
        retryAction: {}
    )
}
