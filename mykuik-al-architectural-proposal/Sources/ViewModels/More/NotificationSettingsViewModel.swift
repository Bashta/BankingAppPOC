import Foundation
import Combine
import OSLog

final class NotificationSettingsViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published var settings: NotificationSettings?
    @Published var pushEnabled: Bool = false
    @Published var emailEnabled: Bool = false
    @Published var smsEnabled: Bool = false
    @Published var transactionAlertsEnabled: Bool = true
    @Published var securityAlertsEnabled: Bool = true  // Always true, cannot disable
    @Published var promotionsEnabled: Bool = false
    @Published var minimumAlertAmount: Decimal = 0
    @Published var minimumAlertAmountText: String = ""
    @Published var isLoading = false
    @Published var isSaving = false
    @Published var error: Error?
    @Published var showSuccessMessage = false

    // MARK: - Dependencies

    private let notificationService: NotificationServiceProtocol
    private weak var coordinator: MoreCoordinator?
    private var hideSuccessMessageTask: Task<Void, Never>?

    // MARK: - Init

    init(notificationService: NotificationServiceProtocol, coordinator: MoreCoordinator) {
        self.notificationService = notificationService
        self.coordinator = coordinator
    }

    deinit {
        hideSuccessMessageTask?.cancel()
    }

    // MARK: - Data Loading

    @MainActor
    func loadData() async {
        isLoading = true
        error = nil
        defer { isLoading = false }

        do {
            let fetchedSettings = try await notificationService.fetchSettings()
            settings = fetchedSettings
            mapSettingsToProperties(fetchedSettings)
        } catch {
            self.error = error
            Logger.more.error("Failed to load notification settings: \(error.localizedDescription)")
        }
    }

    // MARK: - Save Settings

    @MainActor
    func saveSettings() async {
        // Validate minimum alert amount
        guard minimumAlertAmount >= 0 else {
            error = NotificationSettingsError.invalidAmount
            return
        }

        isSaving = true
        error = nil
        defer { isSaving = false }

        do {
            let updatedSettings = NotificationSettings(
                pushEnabled: pushEnabled,
                emailEnabled: emailEnabled,
                smsEnabled: smsEnabled,
                transactionAlertsEnabled: transactionAlertsEnabled,
                securityAlertsEnabled: true,  // Always true
                promotionsEnabled: promotionsEnabled,
                minimumAlertAmount: minimumAlertAmount
            )

            try await notificationService.updateSettings(updatedSettings)
            settings = updatedSettings
            Logger.more.info("Notification settings saved successfully")

            // Show success message
            showSuccessMessage = true

            // Auto-hide success message after 2 seconds
            hideSuccessMessageTask?.cancel()
            hideSuccessMessageTask = Task {
                try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
                if !Task.isCancelled {
                    await MainActor.run {
                        self.showSuccessMessage = false
                    }
                }
            }
        } catch {
            self.error = error
            Logger.more.error("Failed to save notification settings: \(error.localizedDescription)")
        }
    }

    // MARK: - Amount Text Input

    func updateMinimumAlertAmount(_ text: String) {
        minimumAlertAmountText = text

        // Handle empty string
        guard !text.isEmpty else {
            minimumAlertAmount = 0
            return
        }

        // Parse decimal from text
        let cleanedText = text.replacingOccurrences(of: ",", with: ".")
        if let decimal = Decimal(string: cleanedText), decimal >= 0 {
            minimumAlertAmount = decimal
        }
        // Keep previous value if parsing fails (graceful handling)
    }

    // MARK: - Error Handling

    func clearError() {
        error = nil
    }

    // MARK: - Private Helpers

    private func mapSettingsToProperties(_ settings: NotificationSettings) {
        pushEnabled = settings.pushEnabled
        emailEnabled = settings.emailEnabled
        smsEnabled = settings.smsEnabled
        transactionAlertsEnabled = settings.transactionAlertsEnabled
        securityAlertsEnabled = true  // Always true
        promotionsEnabled = settings.promotionsEnabled
        minimumAlertAmount = settings.minimumAlertAmount

        // Format amount text
        if settings.minimumAlertAmount == 0 {
            minimumAlertAmountText = ""
        } else {
            minimumAlertAmountText = "\(settings.minimumAlertAmount)"
        }
    }
}

// MARK: - Notification Settings Error

enum NotificationSettingsError: LocalizedError {
    case invalidAmount

    var errorDescription: String? {
        switch self {
        case .invalidAmount:
            return "Minimum alert amount must be zero or greater"
        }
    }
}
