// ProfileViewModel.swift
// Story 6.3: Profile View and Edit

import Foundation
import Combine
import OSLog

// MARK: - ProfileViewModel (AC: #1, #2, #3)

final class ProfileViewModel: ObservableObject {
    // MARK: - Published Properties (AC: #1)

    @Published var user: User?
    @Published var isLoading = false
    @Published var error: Error?

    // MARK: - Dependencies (AC: #1)

    private let authService: AuthServiceProtocol
    private weak var coordinator: MoreCoordinator?

    // MARK: - Initialization

    init(authService: AuthServiceProtocol, coordinator: MoreCoordinator) {
        self.authService = authService
        self.coordinator = coordinator
        Logger.more.debug("[ProfileViewModel] Initialized")
    }

    // MARK: - Data Loading (AC: #2)

    /// Loads user profile data from AuthService
    /// - Sets isLoading = true during load
    /// - Updates user on success
    /// - Sets error on failure
    @MainActor
    func loadData() async {
        Logger.more.debug("[ProfileViewModel] loadData called")
        isLoading = true
        error = nil
        defer { isLoading = false }

        do {
            let fetchedUser = try await authService.fetchUserProfile()
            self.user = fetchedUser
            Logger.more.info("[ProfileViewModel] Profile loaded successfully for user: \(fetchedUser.username)")
        } catch {
            self.error = error
            Logger.more.error("[ProfileViewModel] Failed to load profile: \(error.localizedDescription)")
        }
    }

    /// Refreshes user profile data (for pull-to-refresh)
    @MainActor
    func refresh() async {
        Logger.more.debug("[ProfileViewModel] refresh called")
        await loadData()
    }

    // MARK: - Navigation (AC: #3)

    /// Navigates to the edit profile screen
    func navigateToEditProfile() {
        Logger.more.debug("[ProfileViewModel] navigateToEditProfile called")
        coordinator?.push(.editProfile)
    }
}
