// MoreMenuView.swift
// Story 2.11: Implement Logout with State Clearing

import SwiftUI

/// More Menu view displaying settings and profile options.
///
/// Story 2.11 Implementation:
/// - AC: #1 - Logout button with destructive styling at bottom of menu
/// - AC: #7 - Logout confirmation alert with Cancel and Logout actions
///
/// Menu Sections:
/// - Account: Profile
/// - Settings: Security, Notifications
/// - Support: Help & Support, About
/// - Logout: Destructive logout action
struct MoreMenuView: View {
    @ObservedObject var viewModel: MoreMenuViewModel

    var body: some View {
        List {
            // MARK: - Account Section
            Section {
                menuRow(
                    title: "Profile",
                    icon: "person.circle",
                    action: viewModel.navigateToProfile
                )
            } header: {
                Text("Account")
            }

            // MARK: - Settings Section
            Section {
                menuRow(
                    title: "Security",
                    icon: "lock.shield",
                    action: viewModel.navigateToSecurity
                )

                menuRow(
                    title: "Notifications",
                    icon: "bell",
                    action: viewModel.navigateToNotificationSettings
                )
            } header: {
                Text("Settings")
            }

            // MARK: - Support Section
            Section {
                menuRow(
                    title: "Help & Support",
                    icon: "questionmark.circle",
                    action: viewModel.navigateToSupport
                )

                menuRow(
                    title: "About",
                    icon: "info.circle",
                    action: viewModel.navigateToAbout
                )
            } header: {
                Text("Support")
            }

            // MARK: - Logout Section (Story 2.11 AC: #1)
            Section {
                Button(action: viewModel.confirmLogout) {
                    HStack {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                            .foregroundColor(.red)
                            .frame(width: 24)
                        Text("Logout")
                            .foregroundColor(.red)
                        Spacer()
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("More")
        .navigationBarTitleDisplayMode(.large)
        // MARK: - Logout Confirmation Alert (Story 2.11 AC: #7)
        .alert("Logout", isPresented: $viewModel.showLogoutConfirmation) {
            Button("Cancel", role: .cancel) {
                viewModel.cancelLogout()
            }
            Button("Logout", role: .destructive) {
                viewModel.logout()
            }
        } message: {
            Text("Are you sure you want to logout?")
        }
    }

    // MARK: - Helper Views

    /// Standard menu row with icon, title, and chevron
    private func menuRow(
        title: String,
        icon: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.accentColor)
                    .frame(width: 24)
                Text(title)
                    .foregroundColor(.primary)
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
                    .font(.caption)
            }
        }
    }
}
