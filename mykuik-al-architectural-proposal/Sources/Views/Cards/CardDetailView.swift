// CardDetailView.swift - Stub for Story 5.2
import SwiftUI

struct CardDetailView: View {
    @ObservedObject var viewModel: CardDetailViewModel

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "creditcard")
                .font(.system(size: 60))
                .foregroundColor(.blue)

            Text("Card Detail")
                .font(.title)
                .fontWeight(.bold)

            Text("Card ID: \(viewModel.cardId)")
                .font(.body)
                .foregroundColor(.secondary)

            Text("This screen will be implemented in Story 5.2")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .navigationTitle("Card Details")
        .navigationBarTitleDisplayMode(.inline)
    }
}
