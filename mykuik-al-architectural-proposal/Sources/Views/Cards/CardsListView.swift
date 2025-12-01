import SwiftUI

// MARK: - CardsListView

/// View displaying all user cards in a horizontal carousel with pull-to-refresh.
struct CardsListView: View {
    @ObservedObject var viewModel: CardsListViewModel

    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.cards.isEmpty {
                LoadingView()
            } else if let error = viewModel.error, viewModel.cards.isEmpty {
                errorView(error: error)
            } else if viewModel.cards.isEmpty {
                emptyStateView
            } else {
                contentView
            }
        }
        .navigationTitle("Cards")
        .navigationBarTitleDisplayMode(.large)
        .task {
            await viewModel.loadData()
        }
        .refreshable {
            await viewModel.refresh()
        }
    }

    // MARK: - Content View

    private var contentView: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Card Carousel
                cardCarousel

                // Card count indicator
                Text("\(viewModel.cards.count) card\(viewModel.cards.count == 1 ? "" : "s")")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Spacer(minLength: 40)
            }
            .padding(.top, 16)
        }
    }

    // MARK: - Card Carousel

    private var cardCarousel: some View {
        VStack(spacing: 16) {
            TabView {
                ForEach(viewModel.cards) { card in
                    Button {
                        viewModel.showCardDetail(card)
                    } label: {
                        CardView(card: card)
                            .padding(.horizontal, 20)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(height: 220)

            // Page indicators below the card
            if viewModel.cards.count > 1 {
                HStack(spacing: 8) {
                    ForEach(0..<viewModel.cards.count, id: \.self) { index in
                        Circle()
                            .fill(index == 0 ? Color.blue : Color.gray.opacity(0.3))
                            .frame(width: 8, height: 8)
                    }
                }
            }
        }
    }

    // MARK: - Empty State View

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "creditcard.trianglebadge.exclamationmark")
                .font(.system(size: 60))
                .foregroundColor(.secondary)

            Text("No Cards")
                .font(.title2)
                .fontWeight(.semibold)

            Text("You don't have any cards yet.\nContact support to request a card.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }

    // MARK: - Error View

    private func errorView(error: Error) -> some View {
        ErrorView(
            message: "Unable to load cards",
            retryAction: {
                Task {
                    await viewModel.loadData()
                }
            }
        )
    }
}
