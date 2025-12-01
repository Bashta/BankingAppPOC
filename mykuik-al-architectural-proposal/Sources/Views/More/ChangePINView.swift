// ChangePINView.swift
// Story 2.10: Implement Change PIN Flow
//
// Change PIN screen for authenticated users.
// Users enter current PIN and new PIN with validation and OTP verification.

import SwiftUI

// MARK: - ChangePINView

/// Change PIN screen for the banking app.
///
/// Features:
/// - Current PIN field (4 digits, numeric keyboard)
/// - New PIN field (4 digits, numeric keyboard)
/// - Confirm PIN field (4 digits, numeric keyboard)
/// - PIN requirements checklist with real-time validation
/// - Submit button with loading state
/// - OTP modal for verification
/// - Success state with checkmark and Done button
/// - Error message display
///
/// Architecture:
/// - Uses @ObservedObject for ViewModel (created by MoreViewFactory)
/// - Delegates all logic to ChangePINViewModel
/// - No navigation logic in view - handled by coordinator via ViewModel
///
/// AC: #6 - Renders PIN change UI
/// AC: #7 - Displays PIN requirements checklist
/// AC: #8 - Implements UI states (loading, error, success)
/// AC: #9 - Presents OTP modal for verification
struct ChangePINView: View {

    // MARK: - Properties

    /// ViewModel managing change PIN state and logic
    @ObservedObject var viewModel: ChangePINViewModel

    // MARK: - Body

    var body: some View {
        ZStack {
            // Main content
            ScrollView {
                VStack(spacing: 24) {
                    if viewModel.hasChanged {
                        // Success State (AC: #8)
                        successView
                            .padding(.top, 60)
                    } else {
                        // Form State (AC: #6, #7)
                        formView
                            .padding(.top, 24)
                    }

                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 20)
            }
            .disabled(viewModel.isChanging)

            // Loading Overlay (AC: #8)
            if viewModel.isChanging && !viewModel.showOTP {
                loadingOverlay
            }
        }
        .navigationTitle("Change PIN")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: viewModel.oldPIN) { _ in
            viewModel.clearError()
        }
        .onChange(of: viewModel.newPIN) { _ in
            viewModel.clearError()
        }
        .onChange(of: viewModel.confirmPIN) { _ in
            viewModel.clearError()
        }
        .sheet(isPresented: $viewModel.showOTP) {
            // OTP Modal (AC: #9)
            otpSheetView
        }
    }

    // MARK: - Form View (AC: #6)

    /// Form with PIN inputs and requirements checklist
    private var formView: some View {
        VStack(spacing: 20) {
            // Current PIN Field (AC: #6)
            pinField(
                label: "Current PIN",
                placeholder: "Enter 4-digit PIN",
                text: $viewModel.oldPIN,
                accessibilityLabel: "Current PIN field"
            )

            // New PIN Field (AC: #6)
            pinField(
                label: "New PIN",
                placeholder: "Enter 4-digit PIN",
                text: $viewModel.newPIN,
                accessibilityLabel: "New PIN field"
            )

            // Confirm PIN Field (AC: #6)
            pinField(
                label: "Confirm New PIN",
                placeholder: "Confirm 4-digit PIN",
                text: $viewModel.confirmPIN,
                accessibilityLabel: "Confirm PIN field"
            )

            // Requirements Checklist (AC: #7)
            requirementsChecklist

            // Error message (AC: #8)
            if let error = viewModel.error {
                errorMessage(error)
            }

            // Change PIN Button (AC: #6)
            changePINButton
                .padding(.top, 8)
        }
    }

    // MARK: - PIN Field (AC: #6)

    /// Secure PIN input field with numeric keyboard
    /// - Parameters:
    ///   - label: Field label text
    ///   - placeholder: Placeholder text
    ///   - text: Binding to PIN text
    ///   - accessibilityLabel: VoiceOver label
    private func pinField(
        label: String,
        placeholder: String,
        text: Binding<String>,
        accessibilityLabel: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)

            SecureField(placeholder, text: text)
                .keyboardType(.numberPad)
                .textContentType(.oneTimeCode)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .disabled(viewModel.isChanging)
                .onChange(of: text.wrappedValue) { newValue in
                    // Limit to 4 digits and filter non-numeric
                    let filtered = newValue.filter { $0.isNumber }
                    if filtered.count > 4 {
                        text.wrappedValue = String(filtered.prefix(4))
                    } else if filtered != newValue {
                        text.wrappedValue = filtered
                    }
                }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
    }

    // MARK: - Requirements Checklist (AC: #7)

    /// PIN requirements checklist with visual indicators
    private var requirementsChecklist: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("PIN Requirements")
                .font(.subheadline)
                .fontWeight(.semibold)

            requirementRow("Current PIN: 4 digits", met: viewModel.isOldPINValid)
            requirementRow("New PIN: 4 digits", met: viewModel.isNewPINValid)
            requirementRow("PINs match", met: viewModel.doPINsMatch)
            requirementRow("Different from current PIN", met: viewModel.pinsDiffer)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }

    /// Individual requirement row with checkmark indicator
    /// - Parameters:
    ///   - text: Requirement description
    ///   - met: Whether the requirement is satisfied
    private func requirementRow(_ text: String, met: Bool) -> some View {
        HStack(spacing: 8) {
            Image(systemName: met ? "checkmark.circle.fill" : "circle")
                .foregroundColor(met ? .green : .gray)
                .font(.body)
            Text(text)
                .font(.caption)
                .foregroundColor(met ? .primary : .secondary)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(text): \(met ? "met" : "not met")")
    }

    // MARK: - Error Message (AC: #8)

    /// Displays error message in red text below form
    private func errorMessage(_ error: Error) -> some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.red)

            Text(error.localizedDescription)
                .font(.caption)
                .foregroundColor(.red)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Error: \(error.localizedDescription)")
    }

    // MARK: - Change PIN Button (AC: #6)

    /// Submit button that triggers PIN change request
    private var changePINButton: some View {
        ActionButton(
            title: "Change PIN",
            isLoading: viewModel.isChanging,
            isDisabled: !viewModel.isFormValid
        ) {
            Task {
                await viewModel.changePIN()
            }
        }
        .accessibilityHint(viewModel.isFormValid
                           ? "Double tap to change your PIN"
                           : "Complete all PIN requirements first")
    }

    // MARK: - Success View (AC: #8)

    /// Success state showing checkmark and Done button
    private var successView: some View {
        VStack(spacing: 24) {
            Spacer()

            // Checkmark icon
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.green)
                .accessibilityHidden(true)

            // Title
            Text("PIN Changed")
                .font(.title2)
                .fontWeight(.bold)

            // Success message
            Text("Your PIN has been changed successfully.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Spacer()

            // Done button
            Button {
                viewModel.dismissAfterSuccess()
            } label: {
                Text("Done")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
            }
            .buttonStyle(.borderedProminent)
            .accessibilityLabel("Done")
            .accessibilityHint("Double tap to return to security settings")
        }
        .padding(.horizontal)
    }

    // MARK: - Loading Overlay (AC: #8)

    /// Loading overlay shown during PIN change
    private var loadingOverlay: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                ProgressView()
                    .scaleEffect(1.2)
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))

                Text("Validating PIN...")
                    .font(.subheadline)
                    .foregroundColor(.white)
            }
            .padding(24)
            .background(Color(.systemGray5))
            .cornerRadius(16)
        }
        .accessibilityLabel("Validating PIN, please wait")
    }

    // MARK: - OTP Sheet View (AC: #9)

    /// OTP verification modal presented after PIN validation
    private var otpSheetView: some View {
        NavigationView {
            VStack(spacing: 24) {
                Spacer()
                    .frame(height: 20)

                // Icon
                Image(systemName: "lock.shield")
                    .font(.system(size: 48))
                    .foregroundColor(.blue)
                    .accessibilityHidden(true)

                // Title
                Text("Enter OTP")
                    .font(.title2)
                    .fontWeight(.bold)

                // Description
                Text("A verification code has been sent to your registered phone number.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                // OTP Input
                TextField("000000", text: $viewModel.otpCode)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.center)
                    .font(.system(size: 32, weight: .semibold, design: .monospaced))
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    .padding(.horizontal, 40)
                    .onChange(of: viewModel.otpCode) { newValue in
                        let filtered = newValue.filter { $0.isNumber }
                        if filtered.count > 6 {
                            viewModel.otpCode = String(filtered.prefix(6))
                        } else if filtered != newValue {
                            viewModel.otpCode = filtered
                        }
                    }
                    .accessibilityLabel("OTP code input")
                    .accessibilityHint("Enter 6-digit verification code")

                // Error message in OTP modal
                if let error = viewModel.error {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.red)

                        Text(error.localizedDescription)
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                    .padding(.horizontal)
                }

                // Verify button
                Button {
                    Task {
                        await viewModel.verifyOTP(viewModel.otpCode)
                    }
                } label: {
                    ZStack {
                        Text("Verify")
                            .fontWeight(.semibold)
                            .opacity(viewModel.isChanging ? 0 : 1)

                        if viewModel.isChanging {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                }
                .buttonStyle(.borderedProminent)
                .disabled(viewModel.otpCode.count != 6 || viewModel.isChanging)
                .opacity(viewModel.otpCode.count != 6 && !viewModel.isChanging ? 0.6 : 1.0)
                .padding(.horizontal)
                .accessibilityLabel("Verify OTP")
                .accessibilityHint(viewModel.otpCode.count == 6
                                   ? "Double tap to verify the code"
                                   : "Enter 6 digits first")

                Spacer()
            }
            .padding()
            .navigationTitle("Verify PIN Change")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        viewModel.dismissOTP()
                    }
                    .accessibilityLabel("Cancel verification")
                }
            }
        }
    }
}
