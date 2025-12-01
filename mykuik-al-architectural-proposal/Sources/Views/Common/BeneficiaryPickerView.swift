//
//  BeneficiaryPickerView.swift
//  BankingApp
//
//  Reusable component for selecting beneficiaries in transfer flows
//

import SwiftUI

struct BeneficiaryPickerView: View {
    let beneficiaries: [Beneficiary]
    @Binding var selectedBeneficiary: Beneficiary?
    let onAddBeneficiary: () -> Void

    @State private var showingPicker = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Beneficiary")
                .font(.caption)
                .foregroundColor(.secondary)

            if beneficiaries.isEmpty {
                emptyStateButton
            } else {
                pickerButton
            }
        }
        .sheet(isPresented: $showingPicker) {
            beneficiaryListSheet
        }
    }

    // MARK: - Empty State Button

    private var emptyStateButton: some View {
        Button(action: onAddBeneficiary) {
            HStack {
                Image(systemName: "person.badge.plus")
                    .foregroundColor(.secondary)
                Text("Add a beneficiary to start")
                    .foregroundColor(.secondary)
                Spacer()
                Image(systemName: "plus.circle")
                    .foregroundColor(.blue)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(10)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Picker Button

    private var pickerButton: some View {
        Button(action: { showingPicker = true }) {
            HStack {
                if let beneficiary = selectedBeneficiary {
                    beneficiaryInfo(beneficiary)
                } else {
                    Text("Select a beneficiary")
                        .foregroundColor(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.down")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(10)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Beneficiary Info

    @ViewBuilder
    private func beneficiaryInfo(_ beneficiary: Beneficiary) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 4) {
                Text(beneficiary.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                if beneficiary.isFavorite {
                    Image(systemName: "star.fill")
                        .font(.caption2)
                        .foregroundColor(.yellow)
                }
            }
            Text("\(beneficiary.bankName ?? "Bank") \u{2022} \(beneficiary.accountNumber.maskedAccountNumber)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    // MARK: - Beneficiary List Sheet

    @ViewBuilder
    private var beneficiaryListSheet: some View {
        NavigationView {
            List {
                // Favorites section
                let favorites = beneficiaries.filter { $0.isFavorite }
                if !favorites.isEmpty {
                    Section("Favorites") {
                        ForEach(favorites) { beneficiary in
                            beneficiaryRow(beneficiary)
                        }
                    }
                }

                // Others section (sorted alphabetically)
                let others = beneficiaries.filter { !$0.isFavorite }.sorted { $0.name < $1.name }
                if !others.isEmpty {
                    Section(favorites.isEmpty ? "Beneficiaries" : "Others") {
                        ForEach(others) { beneficiary in
                            beneficiaryRow(beneficiary)
                        }
                    }
                }

                // Add beneficiary option
                Section {
                    Button(action: {
                        showingPicker = false
                        onAddBeneficiary()
                    }) {
                        HStack {
                            Image(systemName: "person.badge.plus")
                                .foregroundColor(.blue)
                            Text("Add new beneficiary")
                                .foregroundColor(.blue)
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Select Beneficiary")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        showingPicker = false
                    }
                }
            }
        }
    }

    // MARK: - Beneficiary Row

    @ViewBuilder
    private func beneficiaryRow(_ beneficiary: Beneficiary) -> some View {
        Button(action: {
            selectedBeneficiary = beneficiary
            showingPicker = false
        }) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 4) {
                        Text(beneficiary.name)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                        if beneficiary.isFavorite {
                            Image(systemName: "star.fill")
                                .font(.caption2)
                                .foregroundColor(.yellow)
                        }
                    }
                    Text(beneficiary.bankName ?? "Bank")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(beneficiary.accountNumber.maskedAccountNumber)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                if selectedBeneficiary?.id == beneficiary.id {
                    Image(systemName: "checkmark")
                        .foregroundColor(.blue)
                        .font(.caption)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
