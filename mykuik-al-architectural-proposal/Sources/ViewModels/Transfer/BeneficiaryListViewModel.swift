//
//  BeneficiaryListViewModel.swift
//  BankingApp
//

import Foundation
import Combine
import OSLog

final class BeneficiaryListViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var beneficiaries: [Beneficiary] = []
    @Published var filteredBeneficiaries: [Beneficiary] = []
    @Published var isLoading = false
    @Published var isRefreshing = false
    @Published var error: Error?
    @Published var searchQuery: String = ""
    @Published var showDeleteConfirmation = false
    @Published var beneficiaryToDelete: Beneficiary?

    // MARK: - Computed Properties
    var favoriteBeneficiaries: [Beneficiary] {
        filteredBeneficiaries.filter { $0.isFavorite }
    }

    var nonFavoriteBeneficiaries: [Beneficiary] {
        filteredBeneficiaries.filter { !$0.isFavorite }
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    var isEmpty: Bool {
        filteredBeneficiaries.isEmpty && !isLoading
    }

    var isSearching: Bool {
        !searchQuery.isEmpty
    }

    // MARK: - Dependencies
    private let beneficiaryService: BeneficiaryServiceProtocol
    weak var coordinator: TransferCoordinator?
    let selectionMode: Bool

    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization
    init(
        beneficiaryService: BeneficiaryServiceProtocol,
        coordinator: TransferCoordinator?,
        selectionMode: Bool = false
    ) {
        self.beneficiaryService = beneficiaryService
        self.coordinator = coordinator
        self.selectionMode = selectionMode

        setupSearchDebounce()
    }

    private func setupSearchDebounce() {
        $searchQuery
            .debounce(for: .milliseconds(200), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.performSearch()
            }
            .store(in: &cancellables)
    }

    // MARK: - Public Methods
    @MainActor
    func loadData() async {
        // Skip if already loaded to preserve state on back navigation
        guard beneficiaries.isEmpty else { return }

        isLoading = true
        error = nil
        defer { isLoading = false }

        do {
            beneficiaries = try await beneficiaryService.fetchBeneficiaries()
            filteredBeneficiaries = beneficiaries
            Logger.transfer.debug("Loaded \(self.beneficiaries.count) beneficiaries")
        } catch {
            self.error = error
            Logger.transfer.error("Failed to load beneficiaries: \(error.localizedDescription)")
        }
    }

    @MainActor
    func refresh() async {
        isRefreshing = true
        defer { isRefreshing = false }

        do {
            beneficiaries = try await beneficiaryService.fetchBeneficiaries()
            performSearch()
            Logger.transfer.debug("Refreshed beneficiaries: \(self.beneficiaries.count)")
        } catch {
            self.error = error
            Logger.transfer.error("Failed to refresh beneficiaries: \(error.localizedDescription)")
        }
    }

    private func performSearch() {
        if searchQuery.isEmpty {
            filteredBeneficiaries = beneficiaries
        } else {
            let query = searchQuery.lowercased()
            filteredBeneficiaries = beneficiaries.filter { beneficiary in
                beneficiary.name.lowercased().contains(query) ||
                beneficiary.accountNumber.contains(query)
            }
        }
    }

    @MainActor
    func toggleFavorite(_ beneficiary: Beneficiary) async {
        // Optimistic update
        guard let index = beneficiaries.firstIndex(where: { $0.id == beneficiary.id }) else { return }

        var updated = beneficiaries[index]
        let originalFavorite = updated.isFavorite
        updated = Beneficiary(
            id: updated.id,
            name: updated.name,
            accountNumber: updated.accountNumber,
            iban: updated.iban,
            bankName: updated.bankName,
            type: updated.type,
            isFavorite: !originalFavorite
        )
        beneficiaries[index] = updated
        performSearch()

        do {
            _ = try await beneficiaryService.toggleFavorite(id: beneficiary.id)
            Logger.transfer.debug("Toggled favorite for beneficiary: \(beneficiary.name)")
        } catch {
            // Revert on failure
            if let revertIndex = beneficiaries.firstIndex(where: { $0.id == beneficiary.id }) {
                var reverted = beneficiaries[revertIndex]
                reverted = Beneficiary(
                    id: reverted.id,
                    name: reverted.name,
                    accountNumber: reverted.accountNumber,
                    iban: reverted.iban,
                    bankName: reverted.bankName,
                    type: reverted.type,
                    isFavorite: originalFavorite
                )
                beneficiaries[revertIndex] = reverted
                performSearch()
            }
            self.error = error
            Logger.transfer.error("Failed to toggle favorite: \(error.localizedDescription)")
        }
    }

    func confirmDelete(_ beneficiary: Beneficiary) {
        beneficiaryToDelete = beneficiary
        showDeleteConfirmation = true
    }

    @MainActor
    func deleteBeneficiary() async {
        guard let beneficiary = beneficiaryToDelete else { return }

        showDeleteConfirmation = false

        do {
            try await beneficiaryService.deleteBeneficiary(id: beneficiary.id)
            beneficiaries.removeAll { $0.id == beneficiary.id }
            performSearch()
            Logger.transfer.debug("Deleted beneficiary: \(beneficiary.name)")
        } catch {
            self.error = error
            Logger.transfer.error("Failed to delete beneficiary: \(error.localizedDescription)")
        }

        beneficiaryToDelete = nil
    }

    func cancelDelete() {
        showDeleteConfirmation = false
        beneficiaryToDelete = nil
    }

    // MARK: - Navigation
    func showAddBeneficiary() {
        coordinator?.push(.addBeneficiary)
    }

    func showEditBeneficiary(_ beneficiary: Beneficiary) {
        coordinator?.push(.editBeneficiary(beneficiaryId: beneficiary.id))
    }

    func selectForTransfer(_ beneficiary: Beneficiary) {
        // Return selection to calling flow
        coordinator?.pop()
    }

    func handleRowTap(_ beneficiary: Beneficiary) {
        if selectionMode {
            selectForTransfer(beneficiary)
        } else {
            showEditBeneficiary(beneficiary)
        }
    }
}
