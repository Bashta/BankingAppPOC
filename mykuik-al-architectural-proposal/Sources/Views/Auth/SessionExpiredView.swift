//
//  SessionExpiredView.swift
//  BankingApp
//
//  View displayed when user's session expires due to inactivity timeout.
//  Presented as fullscreen cover that cannot be dismissed without action.
//  (Story 2.6 AC: #5)
//

import SwiftUI

/// Session Expired screen displayed when user's session times out.
///
/// Displayed when:
/// - AuthService.handleSessionExpired() triggers after timeout
/// - AppCoordinator.sessionExpired() presents this as fullScreenCover
///
/// UI Components (AC: #5):
/// - SF Symbol icon (clock.badge.exclamationmark) - visual indicator
/// - "Session Expired" title
/// - Explanatory message about security
/// - "Log in Again" primary action button
///
/// Styling:
/// - Consistent with other auth screens (spacing, colors, fonts)
/// - Centered content layout
/// - Prominent call-to-action button
struct SessionExpiredView: View {

    // MARK: - ViewModel

    /// ViewModel managing view state and actions
    @ObservedObject var viewModel: SessionExpiredViewModel

    // MARK: - Body

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            // Session expired icon (AC: #5)
            Image(systemName: "clock.badge.exclamationmark")
                .font(.system(size: 72))
                .foregroundColor(.orange)
                .accessibilityHidden(true)

            // Title
            Text("Session Expired")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.primary)

            // Explanatory message (AC: #5)
            Text("Your session has expired for security reasons. Please log in again to continue.")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal, 32)
                .accessibilityLabel("Your session has expired for security reasons. Please log in again to continue.")

            Spacer()

            // Log in again button (AC: #5)
            Button(action: viewModel.loginAgain) {
                Text("Log in Again")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .accessibilityLabel("Log in Again")
            .accessibilityHint("Returns to the login screen")
            .padding(.horizontal, 32)
            .padding(.bottom, 32)
        }
        .navigationTitle("Session Expired")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true) // Cannot dismiss without action
    }
}

// MARK: - Preview

#if DEBUG
struct SessionExpiredView_Previews: PreviewProvider {
    static var previews: some View {
        // Note: Preview requires mock coordinator setup
        NavigationView {
            Text("Session Expired Preview")
        }
    }
}
#endif
