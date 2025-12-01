import SwiftUI

struct SecureTextField: View {
    @Binding var text: String
    let placeholder: String

    @State private var isSecure: Bool = true

    var body: some View {
        HStack(spacing: 12) {
            if isSecure {
                SecureField(placeholder, text: $text)
                    .textContentType(.password)
                    .autocapitalization(.none)
            } else {
                TextField(placeholder, text: $text)
                    .textContentType(.password)
                    .autocapitalization(.none)
            }

            Button(action: {
                isSecure.toggle()
            }) {
                Image(systemName: isSecure ? "eye.slash" : "eye")
                    .font(.system(size: 16))
                    .foregroundColor(.secondary)
                    .frame(width: 44, height: 44)
            }
            .accessibilityLabel(isSecure ? "Show password" : "Hide password")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}
