import SwiftUI

struct PINEntryView: View {
    @Binding var pin: String
    let digitCount: Int

    @FocusState private var focusedIndex: Int?

    init(pin: Binding<String>, digitCount: Int = 4) {
        self._pin = pin
        self.digitCount = digitCount
    }

    var body: some View {
        HStack(spacing: 12) {
            ForEach(0..<digitCount, id: \.self) { index in
                SecureField("", text: pinBinding(for: index))
                    .focused($focusedIndex, equals: index)
                    .keyboardType(.numberPad)
                    .frame(width: 50, height: 60)
                    .multilineTextAlignment(.center)
                    .font(.title2)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(focusedIndex == index ? Color.accentColor : Color(.systemGray4), lineWidth: 2)
                    )
                    .accessibilityLabel("PIN digit \(index + 1)")
            }
        }
        .onChange(of: pin) { newValue in
            handlePINChange(newValue)
        }
        .onAppear {
            // Auto-focus first field
            focusedIndex = 0
        }
    }

    private func pinBinding(for index: Int) -> Binding<String> {
        Binding(
            get: {
                guard pin.count > index else { return "" }
                let charIndex = pin.index(pin.startIndex, offsetBy: index)
                return String(pin[charIndex])
            },
            set: { newValue in
                var chars = Array(pin)

                // Handle deletion
                if newValue.isEmpty {
                    if chars.count > index {
                        chars.remove(at: index)
                        pin = String(chars)
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
                    pin = String(chars)
                }
            }
        )
    }

    private func handlePINChange(_ newValue: String) {
        // Auto-advance to next field when digit entered
        if let focused = focusedIndex, newValue.count > focused {
            if focused < digitCount - 1 {
                focusedIndex = focused + 1
            } else {
                // Last digit entered, dismiss keyboard
                focusedIndex = nil
            }
        }

        // Ensure PIN doesn't exceed digitCount
        if newValue.count > digitCount {
            pin = String(newValue.prefix(digitCount))
        }
    }
}

// MARK: - Preview

#Preview("PINEntryView - 4 Digits") {
    struct PreviewWrapper: View {
        @State private var pin = ""

        var body: some View {
            VStack(spacing: 20) {
                Text("Enter 4-Digit PIN")
                    .font(.headline)

                PINEntryView(pin: $pin, digitCount: 4)

                Text("Current PIN: \(pin) (\(pin.count) digits)")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Button("Clear") {
                    pin = ""
                }
            }
            .padding()
        }
    }

    return PreviewWrapper()
}

#Preview("PINEntryView - 6 Digits") {
    struct PreviewWrapper: View {
        @State private var pin = ""

        var body: some View {
            VStack(spacing: 20) {
                Text("Enter 6-Digit PIN")
                    .font(.headline)

                PINEntryView(pin: $pin, digitCount: 6)

                Text("Current PIN: \(pin) (\(pin.count) digits)")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Button("Clear") {
                    pin = ""
                }
            }
            .padding()
        }
    }

    return PreviewWrapper()
}
