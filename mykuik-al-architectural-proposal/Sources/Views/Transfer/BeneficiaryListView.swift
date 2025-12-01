//
//  BeneficiaryListView.swift
//  BankingApp
//

import SwiftUI

struct BeneficiaryListView: View {
    @ObservedObject var viewModel: BeneficiaryListViewModel

    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.beneficiaries.isEmpty {
                LoadingView()
            } else if let error = viewModel.error, viewModel.beneficiaries.isEmpty {
                ErrorView(
                    message: "Unable to load beneficiaries",
                    retryAction: { Task { await viewModel.loadData() } }
                )
            } else if viewModel.isEmpty && !viewModel.isSearching {
                emptyStateView
            } else {
                listContent
            }
        }
        .navigationTitle("Beneficiaries")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: viewModel.showAddBeneficiary) {
                    Image(systemName: "plus")
                }
            }
        }
        .task {
            await viewModel.loadData()
        }
        .refreshable {
            await viewModel.refresh()
        }
        .alert("Delete Beneficiary?", isPresented: $viewModel.showDeleteConfirmation) {
            Button("Cancel", role: .cancel) {
                viewModel.cancelDelete()
            }
            Button("Delete", role: .destructive) {
                Task { await viewModel.deleteBeneficiary() }
            }
        } message: {
            if let beneficiary = viewModel.beneficiaryToDelete {
                Text("Are you sure you want to delete \(beneficiary.name)? This cannot be undone.")
            }
        }
    }

    private var listContent: some View {
        VStack(spacing: 0) {
            // Search Bar
            searchBar

            List {
                // Favorites Section
                if !viewModel.favoriteBeneficiaries.isEmpty {
                    Section("Favorites") {
                        ForEach(viewModel.favoriteBeneficiaries) { beneficiary in
                            beneficiaryRow(beneficiary)
                        }
                    }
                }

                // All Beneficiaries Section
                if !viewModel.nonFavoriteBeneficiaries.isEmpty {
                    Section("All Beneficiaries") {
                        ForEach(viewModel.nonFavoriteBeneficiaries) { beneficiary in
                            beneficiaryRow(beneficiary)
                        }
                    }
                }

                // No Results
                if viewModel.filteredBeneficiaries.isEmpty && viewModel.isSearching {
                    Section {
                        HStack {
                            Spacer()
                            Text("No beneficiaries matching '\(viewModel.searchQuery)'")
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                            Spacer()
                        }
                        .padding(.vertical, 32)
                    }
                }
            }
            .listStyle(.insetGrouped)
        }
    }

    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)

            TextField("Search by name or account", text: $viewModel.searchQuery)
                .textFieldStyle(.plain)
                .autocapitalization(.none)
                .disableAutocorrection(true)

            if !viewModel.searchQuery.isEmpty {
                Button(action: { viewModel.searchQuery = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(10)
        .background(Color(.systemGray6))
        .cornerRadius(10)
        .padding(.horizontal)
        .padding(.vertical, 8)
    }

    private func beneficiaryRow(_ beneficiary: Beneficiary) -> some View {
        Button {
            viewModel.handleRowTap(beneficiary)
        } label: {
            BeneficiaryCell(beneficiary: beneficiary)
        }
        .buttonStyle(.plain)
        .swipeActions(edge: .leading, allowsFullSwipe: true) {
            Button {
                Task { await viewModel.toggleFavorite(beneficiary) }
            } label: {
                Image(systemName: beneficiary.isFavorite ? "star.slash" : "star.fill")
            }
            .tint(.yellow)
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(role: .destructive) {
                viewModel.confirmDelete(beneficiary)
            } label: {
                Image(systemName: "trash")
            }
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.crop.circle.badge.plus")
                .font(.system(size: 60))
                .foregroundColor(.secondary)

            Text("No beneficiaries yet")
                .font(.title3)
                .fontWeight(.medium)

            Text("Add a beneficiary to start transferring money")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Button(action: viewModel.showAddBeneficiary) {
                Text("Add Beneficiary")
                    .fontWeight(.medium)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
        }
        .padding()
    }
}

#if DEBUG
struct BeneficiaryListView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            BeneficiaryListView(viewModel: BeneficiaryListViewModel(
                beneficiaryService: MockBeneficiaryService(),
                coordinator: nil,
                selectionMode: false
            ))
        }
        .navigationViewStyle(.stack)
    }
}
#endif
