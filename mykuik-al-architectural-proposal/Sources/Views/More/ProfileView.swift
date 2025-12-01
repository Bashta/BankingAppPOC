// ProfileView.swift
// Story 6.3: Profile View and Edit

import SwiftUI

// MARK: - ProfileView (AC: #4, #5, #6)

struct ProfileView: View {
    @ObservedObject var viewModel: ProfileViewModel

    var body: some View {
        Group {
            if let user = viewModel.user {
                // AC: #5 - Content state (show content if we have user data)
                profileContent(user: user)
            } else if let error = viewModel.error, !viewModel.isLoading {
                // AC: #6 - Error state (only show if not currently loading)
                ErrorView(
                    message: "Unable to load profile",
                    retryAction: {
                        Task { await viewModel.loadData() }
                    }
                )
            } else {
                // AC: #4 - Loading state (default when no user and no error)
                LoadingView(message: "Loading profile...")
            }
        }
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            // AC: #5 - Edit button in nav bar (trailing)
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Edit") {
                    viewModel.navigateToEditProfile()
                }
                .disabled(viewModel.user == nil)
            }
        }
        .task {
            // AC: #4 - Initial load
            await viewModel.loadData()
        }
    }

    // MARK: - Profile Content (AC: #5)

    @ViewBuilder
    private func profileContent(user: User) -> some View {
        ScrollView {
            VStack(spacing: 24) {
                // Profile Avatar Placeholder (AC: #5)
                profileAvatarSection(user: user)

                // User Info Section (AC: #5)
                userInfoSection(user: user)

                // Address Section (AC: #5)
                if let address = user.address {
                    addressSection(address: address)
                }

                Spacer(minLength: 20)
            }
            .padding()
        }
    }

    // MARK: - Profile Avatar Section

    @ViewBuilder
    private func profileAvatarSection(user: User) -> some View {
        VStack(spacing: 12) {
            // AC: #5 - Profile avatar placeholder (SF Symbol: person.circle.fill)
            Image(systemName: "person.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.accentColor)
                .accessibilityLabel("Profile picture")

            // AC: #5 - User name (firstName + lastName)
            Text(user.name)
                .font(.title2)
                .fontWeight(.semibold)

            Text("@\(user.username)")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 8)
    }

    // MARK: - User Info Section

    @ViewBuilder
    private func userInfoSection(user: User) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Contact Information")
                .font(.headline)
                .foregroundColor(.primary)

            // AC: #5 - Email address
            ProfileInfoRow(
                icon: "envelope.fill",
                label: "Email",
                value: user.email
            )

            // AC: #5 - Phone number
            ProfileInfoRow(
                icon: "phone.fill",
                label: "Phone",
                value: formatPhoneNumber(user.phoneNumber)
            )
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
    }

    // MARK: - Address Section

    @ViewBuilder
    private func addressSection(address: Address) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Address")
                .font(.headline)
                .foregroundColor(.primary)

            // AC: #5 - Street
            ProfileInfoRow(
                icon: "house.fill",
                label: "Street",
                value: address.street
            )

            // AC: #5 - City, State, Zip
            ProfileInfoRow(
                icon: "building.2.fill",
                label: "City",
                value: "\(address.city), \(address.state) \(address.zipCode)"
            )
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
    }

    // MARK: - Helpers

    /// Formats phone number for display
    private func formatPhoneNumber(_ phone: String) -> String {
        let digits = phone.filter { $0.isNumber }
        guard digits.count == 10 else { return phone }
        let areaCode = String(digits.prefix(3))
        let middle = String(digits.dropFirst(3).prefix(3))
        let last = String(digits.suffix(4))
        return "(\(areaCode)) \(middle)-\(last)"
    }
}

// MARK: - ProfileInfoRow Component

private struct ProfileInfoRow: View {
    let icon: String
    let label: String
    let value: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(.accentColor)
                .frame(width: 24, height: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption)
                    .foregroundColor(.secondary)

                Text(value)
                    .font(.body)
                    .foregroundColor(.primary)
            }

            Spacer()
        }
    }
}

