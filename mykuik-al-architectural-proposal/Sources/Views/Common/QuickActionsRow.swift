//
//  QuickActionsRow.swift
//  BankingApp
//
//  Horizontal row of quick action buttons for account detail and other screens.
//  Story 3.2: Implement Account Detail View with Balance Card
//

import SwiftUI

// MARK: - QuickAction Model

struct QuickAction: Identifiable {
    let id = UUID()
    let title: String
    let icon: String
    let action: () -> Void
}

// MARK: - QuickActionsRow

struct QuickActionsRow: View {
    let actions: [QuickAction]

    var body: some View {
        HStack(spacing: 16) {
            ForEach(actions) { action in
                QuickActionButton(action: action)
            }
        }
    }
}

// MARK: - QuickActionButton

struct QuickActionButton: View {
    let action: QuickAction

    var body: some View {
        Button(action: action.action) {
            VStack(spacing: 8) {
                Image(systemName: action.icon)
                    .font(.title2)
                    .foregroundColor(.accentColor)

                Text(action.title)
                    .font(.caption)
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(action.title)
    }
}
