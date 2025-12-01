import SwiftUI

struct NotificationSettingsView: View {
    @ObservedObject var viewModel: NotificationSettingsViewModel

    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.settings == nil {
                LoadingView()
            } else {
                settingsContent
            }
        }
        .navigationTitle("Notification Settings")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.loadData()
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
            if viewModel.showSuccessMessage {
                successBanner
            }
        }
    }

    // MARK: - Settings Content

    private var settingsContent: some View {
        Form {
            // MARK: - Notification Channels Section
            Section {
                channelToggle(
                    title: "Push Notifications",
                    subtitle: "Receive push notifications on this device",
                    icon: "bell.fill",
                    isOn: $viewModel.pushEnabled
                )

                channelToggle(
                    title: "Email Notifications",
                    subtitle: "Receive notifications via email",
                    icon: "envelope.fill",
                    isOn: $viewModel.emailEnabled
                )

                channelToggle(
                    title: "SMS Notifications",
                    subtitle: "Receive notifications via SMS",
                    icon: "message.fill",
                    isOn: $viewModel.smsEnabled
                )
            } header: {
                Text("Notification Channels")
            }

            // MARK: - Notification Types Section
            Section {
                typeToggle(
                    title: "Transaction Alerts",
                    subtitle: "Receive alerts for account transactions",
                    icon: "creditcard.fill",
                    isOn: $viewModel.transactionAlertsEnabled
                )

                // Security Alerts - Always enabled, cannot disable
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Label("Security Alerts", systemImage: "shield.fill")
                            .foregroundColor(.secondary)
                        Spacer()
                        Toggle("", isOn: .constant(true))
                            .labelsHidden()
                            .disabled(true)
                    }

                    Text("Always enabled for your security")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 2)

                typeToggle(
                    title: "Promotions",
                    subtitle: "Receive promotional offers and updates",
                    icon: "tag.fill",
                    isOn: $viewModel.promotionsEnabled
                )
            } header: {
                Text("Notification Types")
            }

            // MARK: - Alert Threshold Section
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Minimum Transaction Amount")
                        .font(.subheadline)
                        .foregroundColor(.primary)

                    HStack {
                        Text("$")
                            .foregroundColor(.secondary)

                        TextField("0.00", text: $viewModel.minimumAlertAmountText)
                            .keyboardType(.decimalPad)
                            .onChange(of: viewModel.minimumAlertAmountText) { newValue in
                                viewModel.updateMinimumAlertAmount(newValue)
                            }
                    }
                    .padding(10)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)

                    Text("Only notify for transactions above this amount")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            } header: {
                Text("Alert Threshold")
            }

            // MARK: - Save Button Section
            Section {
                Button(action: {
                    Task {
                        await viewModel.saveSettings()
                    }
                }) {
                    HStack {
                        Spacer()
                        if viewModel.isSaving {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                        } else {
                            Text("Save Settings")
                                .fontWeight(.semibold)
                        }
                        Spacer()
                    }
                }
                .disabled(viewModel.isSaving)
                .foregroundColor(viewModel.isSaving ? .secondary : .accentColor)
            }
        }
    }

    // MARK: - Channel Toggle

    private func channelToggle(
        title: String,
        subtitle: String,
        icon: String,
        isOn: Binding<Bool>
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Label(title, systemImage: icon)
                Spacer()
                Toggle("", isOn: isOn)
                    .labelsHidden()
            }

            Text(subtitle)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 2)
    }

    // MARK: - Type Toggle

    private func typeToggle(
        title: String,
        subtitle: String,
        icon: String,
        isOn: Binding<Bool>
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Label(title, systemImage: icon)
                Spacer()
                Toggle("", isOn: isOn)
                    .labelsHidden()
            }

            Text(subtitle)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 2)
    }

    // MARK: - Success Banner

    private var successBanner: some View {
        VStack {
            Spacer()

            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                Text("Settings saved successfully")
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
        .animation(.easeInOut, value: viewModel.showSuccessMessage)
    }

    // MARK: - Error Binding

    private var errorBinding: Binding<Bool> {
        Binding(
            get: { viewModel.error != nil },
            set: { if !$0 { viewModel.clearError() } }
        )
    }
}
