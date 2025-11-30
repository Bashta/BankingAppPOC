//
//  TransactionHistoryView.swift
//  BankingApp
//
//  Transaction history view with search, filtering, and infinite scroll pagination.
//  Story 3.3: Implement Transaction History with Search and Filtering
//

import SwiftUI

struct TransactionHistoryView: View {
    @ObservedObject var viewModel: TransactionHistoryViewModel

    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.transactions.isEmpty {
                LoadingView(message: "Loading transactions...")
            } else if viewModel.error != nil && viewModel.transactions.isEmpty {
                ErrorView(
                    message: "Unable to load transactions. Please try again.",
                    retryAction: { Task { await viewModel.loadData() } }
                )
            } else if viewModel.transactions.isEmpty {
                emptyStateView
            } else {
                transactionsList
            }
        }
        .navigationTitle("Transactions")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                filterButton
            }
        }
        .searchable(text: $viewModel.searchQuery, prompt: "Search transactions")
        .sheet(isPresented: $viewModel.showingFilterSheet) {
            FilterSheetView(
                selectedCategories: $viewModel.selectedCategories,
                dateRange: $viewModel.dateRange,
                onApply: { Task { await viewModel.applyFilters() } },
                onClear: viewModel.clearFilters
            )
        }
        .task {
            await viewModel.loadData()
        }
    }

    // MARK: - Filter Button

    private var filterButton: some View {
        Button(action: viewModel.toggleFilterSheet) {
            ZStack(alignment: .topTrailing) {
                Image(systemName: "line.3.horizontal.decrease.circle")
                    .font(.body)

                if viewModel.hasActiveFilters {
                    Circle()
                        .fill(Color.accentColor)
                        .frame(width: 8, height: 8)
                        .offset(x: 2, y: -2)
                }
            }
        }
        .accessibilityLabel(viewModel.hasActiveFilters ? "Filter (active)" : "Filter")
    }

    // MARK: - Empty State View

    private var emptyStateView: some View {
        Group {
            if viewModel.searchQuery.isEmpty && !viewModel.hasActiveFilters {
                EmptyStateView(
                    iconName: "list.bullet.rectangle",
                    title: "No Transactions",
                    message: "No transactions found for this account."
                )
            } else {
                EmptyStateView(
                    iconName: "magnifyingglass",
                    title: "No Results",
                    message: "No transactions match your search or filters.",
                    actionTitle: "Clear Filters",
                    action: viewModel.clearFilters
                )
            }
        }
    }

    // MARK: - Transactions List

    private var transactionsList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(viewModel.transactions) { transaction in
                    VStack(spacing: 0) {
                        Button {
                            viewModel.showTransactionDetail(transaction)
                        } label: {
                            TransactionCell(transaction: transaction)
                                .padding(.horizontal)
                                .padding(.vertical, 8)
                        }
                        .buttonStyle(.plain)

                        Divider()
                            .padding(.leading, 68) // Align with text after icon
                    }
                    .onAppear {
                        // Infinite scroll trigger - load more when last item appears
                        if transaction.id == viewModel.transactions.last?.id {
                            Task { await viewModel.loadMore() }
                        }
                    }
                }

                // Loading more indicator
                if viewModel.isLoadingMore {
                    HStack {
                        Spacer()
                        ProgressView()
                            .padding()
                        Spacer()
                    }
                }
            }
        }
        .refreshable {
            await viewModel.refresh()
        }
    }
}

// MARK: - Preview

// Note: Preview requires full coordinator setup which is complex.
// Use the app's AccountsViewFactory for proper instantiation.
