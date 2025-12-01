import SwiftUI

struct OTPInputView: View {
    @Binding var otp: String

    @FocusState private var focusedIndex: Int?

    var body: some View {
        HStack(spacing: 12) {
            ForEach(0..<6, id: \.self) { index in
                TextField("", text: otpBinding(for: index))
                    .focused($focusedIndex, equals: index)
                    .keyboardType(.numberPad)
                    .frame(width: 50, height: 60)
                    .multilineTextAlignment(.center)
                    .font(.title2)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(focusedIndex == index ? Color.accentColor : Color(.systemGray4), lineWidth: 2)
                    )
                    .accessibilityLabel("OTP digit \(index + 1)")
            }
        }
        .onChange(of: otp) { newValue in
            handleOTPChange(newValue)
        }
        .onAppear {
            // Auto-focus first field
            focusedIndex = 0
            // Check clipboard for 6-digit code
            checkClipboardForOTP()
        }
    }

    private func otpBinding(for index: Int) -> Binding<String> {
        Binding(
            get: {
                guard otp.count > index else { return "" }
                let charIndex = otp.index(otp.startIndex, offsetBy: index)
                return String(otp[charIndex])
            },
            set: { newValue in
                var chars = Array(otp)

                // Handle deletion
                if newValue.isEmpty {
                    if chars.count > index {
                        chars.remove(at: index)
                        otp = String(chars)
                        // Move focus back
                        if index > 0 {
                            focusedIndex = index - 1
                        }
                    }
                } else {
                    // Get only the last character if multiple entered
                    let digit = String(newValue.last ?? Character(""))

                    // Only allow digits
                    guard digit.allSatisfy({ $0.isNumber }) else { return }

                    if chars.count > index {
                        chars[index] = digit.last ?? Character("")
                    } else if chars.count == index {
                        chars.append(digit.last ?? Character(""))
                    }
                    otp = String(chars)
                }
            }
        )
    }

    private func handleOTPChange(_ newValue: String) {
        // Auto-advance to next field when digit entered
        if let focused = focusedIndex, newValue.count > focused {
            if focused < 5 {
                focusedIndex = focused + 1
            } else {
                // Last digit entered, dismiss keyboard
                focusedIndex = nil
            }
        }

        // Ensure OTP doesn't exceed 6 digits
        if newValue.count > 6 {
            otp = String(newValue.prefix(6))
        }
    }

    private func checkClipboardForOTP() {
        #if !targetEnvironment(macCatalyst)
        if let clipboardString = UIPasteboard.general.string,
           clipboardString.count == 6,
           clipboardString.allSatisfy({ $0.isNumber }) {
            // Paste the OTP code
            otp = clipboardString
        }
        #endif
    }
}
