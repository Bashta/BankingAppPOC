//
//  StatementViewModel.swift
//  BankingApp
//
//  ViewModel for statement generation - manages month/year selection,
//  account info, and statement download functionality.
//

import Foundation
import Combine
import os.log

final class StatementViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published var selectedMonth: Int
    @Published var selectedYear: Int
    @Published var isGenerating = false
    @Published var error: Error?
    @Published var downloadURL: URL?
    @Published var account: Account?

    // MARK: - Properties

    let accountId: String

    /// Available years for picker (current year back 5 years)
    var availableYears: [Int] {
        let currentYear = Calendar.current.component(.year, from: Date())
        return Array((currentYear - 5)...currentYear).reversed()
    }

    /// Month names using DateFormatter for localization
    var monthNames: [String] {
        DateFormatter().monthSymbols
    }

    /// Validates that selected date is not in the future
    var isValidSelection: Bool {
        let currentDate = Date()
        let currentYear = Calendar.current.component(.year, from: currentDate)
        let currentMonth = Calendar.current.component(.month, from: currentDate)

        if selectedYear > currentYear { return false }
        if selectedYear == currentYear && selectedMonth > currentMonth { return false }
        return true
    }

    // MARK: - Dependencies

    private let accountService: AccountServiceProtocol
    weak var coordinator: AccountsCoordinator?

    // MARK: - Initialization

    init(
        accountId: String,
        accountService: AccountServiceProtocol,
        coordinator: AccountsCoordinator?
    ) {
        self.accountId = accountId
        self.accountService = accountService
        self.coordinator = coordinator

        // Default to current month/year
        let currentDate = Date()
        self.selectedMonth = Calendar.current.component(.month, from: currentDate)
        self.selectedYear = Calendar.current.component(.year, from: currentDate)

        Logger.accounts.debug("StatementViewModel initialized for account: \(accountId)")
    }

    // MARK: - Public Methods

    /// Loads account details for display in the statement view
    @MainActor
    func loadAccount() async {
        do {
            account = try await accountService.fetchAccount(id: accountId)
            Logger.accounts.debug("Loaded account for statement: \(self.accountId)")
        } catch {
            self.error = error
            Logger.accounts.error("Failed to load account for statement: \(error.localizedDescription)")
        }
    }

    /// Generates a statement for the selected month and year
    @MainActor
    func generateStatement() async {
        guard isValidSelection else {
            error = StatementError.invalidDateSelection
            return
        }

        isGenerating = true
        error = nil
        downloadURL = nil
        defer { isGenerating = false }

        do {
            downloadURL = try await accountService.generateStatement(
                accountId: accountId,
                month: selectedMonth,
                year: selectedYear
            )
            Logger.accounts.debug("Generated statement for \(self.selectedMonth)/\(self.selectedYear)")
        } catch {
            self.error = error
            Logger.accounts.error("Failed to generate statement: \(error.localizedDescription)")
        }
    }

    /// Triggers share sheet with the download URL
    /// Share sheet is handled by the View using downloadURL
    func shareStatement() {
        Logger.accounts.debug("Sharing statement: \(self.downloadURL?.absoluteString ?? "nil")")
    }
}

// MARK: - Statement Error

enum StatementError: LocalizedError {
    case invalidDateSelection
    case generationFailed

    var errorDescription: String? {
        switch self {
        case .invalidDateSelection:
            return "Cannot generate statement for future dates"
        case .generationFailed:
            return "Failed to generate statement. Please try again."
        }
    }
}
