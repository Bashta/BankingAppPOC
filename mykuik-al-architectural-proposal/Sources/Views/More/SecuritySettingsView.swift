// SecuritySettingsView.swift
// BankingApp
//
// Security settings screen for managing biometric authentication preferences.
// Allows users to enable/disable Face ID/Touch ID for login.

import SwiftUI

struct SecuritySettingsView: View {
    @ObservedObject var viewModel: SecuritySettingsViewModel

    /// Tracks the last known toggle state to detect user-initiated changes.
    @State private var lastKnownToggleState: Bool = false

    var body: some View {
        List {
            // MARK: - Biometric Authentication Section
            Section {
                biometricToggleRow
            } header: {
                Text("Biometric Authentication")
            } footer: {
                Text(viewModel.statusText)
                    .foregroundColor(.secondary)
            }

            // MARK: - Other Security Options Section (Placeholder for future)
            Section {
                NavigationLink(destination: Text("Change Password")) {
                    Label("Change Password", systemImage: "lock.rotation")
                }

                NavigationLink(destination: Text("Change PIN")) {
                    Label("Change PIN", systemImage: "key.fill")
                }
            } header: {
                Text("Account Security")
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Security Settings")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.loadBiometricStatus()
            lastKnownToggleState = viewModel.biometricEnabled
        }
        .alert("Error", isPresented: errorBinding) {
            Button("OK") {
                viewModel.clearError()
            }
        } message: {
            if let error = viewModel.error {
                Text(error.localizedDescription)
            }
        }
        .overlay {
            if let message = viewModel.successMessage {
                successToast(message: message)
            }
        }
    }

    // MARK: - Biometric Toggle Row

    private var biometricToggleRow: some View {
        HStack {
            Label(viewModel.biometricTypeName, systemImage: viewModel.biometricIconName)
                .foregroundColor(viewModel.biometricAvailable ? .primary : .secondary)

            Spacer()

            if viewModel.isLoading {
                ProgressView()
                    .progressViewStyle(.circular)
            } else {
                Toggle("", isOn: Binding(
                    get: { viewModel.biometricEnabled },
                    set: { newValue in
                        // Only trigger if this is a real user change
                        guard newValue != lastKnownToggleState else { return }
                        lastKnownToggleState = newValue
                        Task {
                            await viewModel.toggleBiometric(newValue)
                            // Update tracked state after toggle completes
                            lastKnownToggleState = viewModel.biometricEnabled
                        }
                    }
                ))
                .labelsHidden()
                .disabled(!viewModel.biometricAvailable)
            }
        }
    }

    // MARK: - Success Toast

    private func successToast(message: String) -> some View {
        VStack {
            Spacer()

            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                Text(message)
                    .font(.subheadline)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
            )
            .padding(.bottom, 20)
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
        .animation(.easeInOut, value: viewModel.successMessage != nil)
        .onAppear {
            // Auto-dismiss success message after 2 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                viewModel.clearSuccessMessage()
            }
        }
    }

    // MARK: - Bindings

    /// Binding for error alert presentation.
    private var errorBinding: Binding<Bool> {
        Binding(
            get: { viewModel.error != nil },
            set: { if !$0 { viewModel.clearError() } }
        )
    }
}

