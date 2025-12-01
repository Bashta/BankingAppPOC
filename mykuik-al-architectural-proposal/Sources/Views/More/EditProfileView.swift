// EditProfileView.swift
// Story 6.3: Profile View and Edit

import SwiftUI

// MARK: - EditProfileView (AC: #12, #13, #14, #15)

struct EditProfileView: View {
    @ObservedObject var viewModel: EditProfileViewModel

    // State for error alert
    @State private var showErrorAlert = false

    var body: some View {
        Group {
            if viewModel.isLoading {
                // AC: #12 - Loading state
                LoadingView(message: "Loading profile...")
            } else {
                // AC: #13 - Editable form
                formContent
            }
        }
        .navigationTitle("Edit Profile")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            // AC: #12 - Initial load
            await viewModel.loadData()
        }
        // AC: #15 - Error alert
        .alert("Error", isPresented: $showErrorAlert) {
            Button("OK", role: .cancel) {
                viewModel.error = nil
            }
        } message: {
            Text(viewModel.error?.localizedDescription ?? "An error occurred")
        }
        .onChange(of: viewModel.error != nil) { hasError in
            showErrorAlert = hasError
        }
    }

    // MARK: - Form Content (AC: #13)

    @ViewBuilder
    private var formContent: some View {
        Form {
            // AC: #13 - Personal Information Section
            Section("Personal Information") {
                // First Name TextField
                VStack(alignment: .leading, spacing: 4) {
                    TextField("First Name", text: $viewModel.firstName)
                        .textContentType(.givenName)
                        .autocapitalization(.words)

                    // AC: #15 - Validation error inline
                    if let error = viewModel.validationErrors["firstName"] {
                        validationErrorText(error)
                    }
                }

                // Last Name TextField
                VStack(alignment: .leading, spacing: 4) {
                    TextField("Last Name", text: $viewModel.lastName)
                        .textContentType(.familyName)
                        .autocapitalization(.words)

                    // AC: #15 - Validation error inline
                    if let error = viewModel.validationErrors["lastName"] {
                        validationErrorText(error)
                    }
                }
            }

            // AC: #13 - Contact Section
            Section("Contact") {
                // Email TextField with .emailAddress keyboard
                VStack(alignment: .leading, spacing: 4) {
                    TextField("Email", text: $viewModel.email)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)

                    // AC: #15 - Validation error inline
                    if let error = viewModel.validationErrors["email"] {
                        validationErrorText(error)
                    }
                }

                // Phone TextField with .phonePad keyboard
                VStack(alignment: .leading, spacing: 4) {
                    TextField("Phone", text: $viewModel.phone)
                        .textContentType(.telephoneNumber)
                        .keyboardType(.phonePad)

                    // AC: #15 - Validation error inline
                    if let error = viewModel.validationErrors["phone"] {
                        validationErrorText(error)
                    }
                }
            }

            // AC: #13 - Address Section
            Section("Address") {
                // Street TextField
                TextField("Street", text: $viewModel.street)
                    .textContentType(.streetAddressLine1)

                // City TextField
                TextField("City", text: $viewModel.city)
                    .textContentType(.addressCity)

                // State TextField
                TextField("State", text: $viewModel.state)
                    .textContentType(.addressState)

                // Zip Code TextField with .numberPad keyboard
                TextField("Zip Code", text: $viewModel.zipCode)
                    .textContentType(.postalCode)
                    .keyboardType(.numberPad)
            }

            // AC: #14 - Action Buttons Section
            Section {
                // Save Button
                saveButton

                // Cancel Button
                cancelButton
            }
        }
    }

    // MARK: - Save Button (AC: #14)

    @ViewBuilder
    private var saveButton: some View {
        Button(action: {
            Task { await viewModel.saveProfile() }
        }) {
            HStack {
                Spacer()
                if viewModel.isSaving {
                    // AC: #14 - Shows "Saving..." with ProgressView
                    ProgressView()
                        .padding(.trailing, 8)
                    Text("Saving...")
                } else {
                    Text("Save")
                }
                Spacer()
            }
        }
        .foregroundColor(.white)
        .listRowBackground(Color.accentColor)
        // AC: #14 - Disabled when isSaving = true
        .disabled(viewModel.isSaving)
    }

    // MARK: - Cancel Button (AC: #14)

    @ViewBuilder
    private var cancelButton: some View {
        Button(action: {
            viewModel.cancel()
        }) {
            HStack {
                Spacer()
                Text("Cancel")
                Spacer()
            }
        }
        .foregroundColor(.red)
        // AC: #14 - Disabled when isSaving = true
        .disabled(viewModel.isSaving)
    }

    // MARK: - Validation Error Text (AC: #15)

    @ViewBuilder
    private func validationErrorText(_ message: String) -> some View {
        Text(message)
            .font(.caption)
            .foregroundColor(.red)
    }
}

