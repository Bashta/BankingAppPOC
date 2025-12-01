// EditProfileViewModel.swift
// Story 6.3: Profile View and Edit

import Foundation
import Combine
import OSLog

// MARK: - EditProfileViewModel (AC: #7, #8, #9, #10, #11)

final class EditProfileViewModel: ObservableObject {
    // MARK: - Published Form Fields (AC: #7)

    @Published var firstName: String = ""
    @Published var lastName: String = ""
    @Published var email: String = ""
    @Published var phone: String = ""
    @Published var street: String = ""
    @Published var city: String = ""
    @Published var state: String = ""
    @Published var zipCode: String = ""

    // MARK: - Published State (AC: #7)

    @Published var isLoading = false
    @Published var isSaving = false
    @Published var error: Error?
    @Published var validationErrors: [String: String] = [:]

    // MARK: - Computed Properties (AC: #9)

    /// Returns true if no validation errors exist
    var isValid: Bool {
        validationErrors.isEmpty
    }

    // MARK: - Dependencies (AC: #7)

    private let authService: AuthServiceProtocol
    private weak var coordinator: MoreCoordinator?

    /// Original user ID (preserved during edits)
    private var userId: String = ""
    private var username: String = ""

    // MARK: - Initialization

    init(authService: AuthServiceProtocol, coordinator: MoreCoordinator) {
        self.authService = authService
        self.coordinator = coordinator
        Logger.more.debug("[EditProfileViewModel] Initialized")
    }

    // MARK: - Data Loading (AC: #8)

    /// Loads user profile data and populates form fields
    @MainActor
    func loadData() async {
        Logger.more.debug("[EditProfileViewModel] loadData called")
        isLoading = true
        error = nil
        defer { isLoading = false }

        do {
            let user = try await authService.fetchUserProfile()
            populateFields(from: user)
            Logger.more.info("[EditProfileViewModel] Profile loaded and fields populated")
        } catch {
            self.error = error
            Logger.more.error("[EditProfileViewModel] Failed to load profile: \(error.localizedDescription)")
        }
    }

    /// Populates form fields from User object
    private func populateFields(from user: User) {
        self.userId = user.id
        self.username = user.username

        // Parse name into first and last
        let nameParts = user.name.split(separator: " ", maxSplits: 1)
        self.firstName = nameParts.first.map(String.init) ?? ""
        self.lastName = nameParts.count > 1 ? String(nameParts[1]) : ""

        self.email = user.email
        self.phone = user.phoneNumber

        // Populate address fields
        if let address = user.address {
            self.street = address.street
            self.city = address.city
            self.state = address.state
            self.zipCode = address.zipCode
        }

        Logger.more.debug("[EditProfileViewModel] Fields populated: \(self.firstName) \(self.lastName)")
    }

    // MARK: - Validation (AC: #9)

    /// Validates all form fields and populates validationErrors dictionary
    /// - Returns: true if all fields are valid, false otherwise
    func validateFields() -> Bool {
        Logger.more.debug("[EditProfileViewModel] validateFields called")
        validationErrors.removeAll()

        // Validate firstName is not empty
        if firstName.trimmingCharacters(in: .whitespaces).isEmpty {
            validationErrors["firstName"] = "First name is required"
        }

        // Validate lastName is not empty
        if lastName.trimmingCharacters(in: .whitespaces).isEmpty {
            validationErrors["lastName"] = "Last name is required"
        }

        // Validate email format using regex
        if !isValidEmail(email) {
            validationErrors["email"] = "Invalid email format"
        }

        // Validate phone format (digits only, 10+ chars)
        if !isValidPhone(phone) {
            validationErrors["phone"] = "Invalid phone number"
        }

        let isValid = validationErrors.isEmpty
        Logger.more.debug("[EditProfileViewModel] Validation result: \(isValid), errors: \(self.validationErrors.count)")
        return isValid
    }

    /// Validates email format using regex
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = #"^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#
        return email.range(of: emailRegex, options: .regularExpression) != nil
    }

    /// Validates phone format (at least 10 digits)
    private func isValidPhone(_ phone: String) -> Bool {
        let digits = phone.filter { $0.isNumber }
        return digits.count >= 10
    }

    // MARK: - Save (AC: #10)

    /// Saves the updated profile
    /// - Validates fields first
    /// - Constructs User object and calls authService.updateUserProfile
    /// - Pops navigation on success
    @MainActor
    func saveProfile() async {
        Logger.more.debug("[EditProfileViewModel] saveProfile called")

        // Clear previous errors
        error = nil

        // Validate fields first
        guard validateFields() else {
            Logger.more.debug("[EditProfileViewModel] Validation failed, not saving")
            return
        }

        isSaving = true
        defer { isSaving = false }

        do {
            // Construct User object from form fields
            let address = Address(
                street: street,
                city: city,
                state: state,
                zipCode: zipCode,
                country: "USA" // Default country
            )

            let fullName = "\(firstName.trimmingCharacters(in: .whitespaces)) \(lastName.trimmingCharacters(in: .whitespaces))"

            let updatedUser = User(
                id: userId,
                username: username,
                name: fullName,
                email: email.trimmingCharacters(in: .whitespaces),
                phoneNumber: phone.trimmingCharacters(in: .whitespaces),
                address: address
            )

            // Call service to update profile
            _ = try await authService.updateUserProfile(updatedUser)

            Logger.more.info("[EditProfileViewModel] Profile saved successfully")

            // Pop navigation on success (AC: #10)
            coordinator?.pop()
        } catch {
            self.error = error
            Logger.more.error("[EditProfileViewModel] Failed to save profile: \(error.localizedDescription)")
        }
    }

    // MARK: - Cancel (AC: #11)

    /// Cancels editing and returns to profile view
    /// Discards any unsaved changes
    func cancel() {
        Logger.more.debug("[EditProfileViewModel] cancel called - discarding changes")
        coordinator?.pop()
    }
}
