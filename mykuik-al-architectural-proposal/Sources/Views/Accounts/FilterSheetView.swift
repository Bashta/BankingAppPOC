//
//  FilterSheetView.swift
//  BankingApp
//
//  Filter sheet for transaction history with date range and category selection.
//  Story 3.3: Implement Transaction History with Search and Filtering
//

import SwiftUI

struct FilterSheetView: View {
    @Binding var selectedCategories: Set<TransactionCategory>
    @Binding var dateRange: (start: Date, end: Date)?
    let onApply: () -> Void
    let onClear: () -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var startDate = Date().addingTimeInterval(-30 * 24 * 60 * 60) // 30 days ago
    @State private var endDate = Date()
    @State private var useDateRange = false

    var body: some View {
        NavigationView {
            Form {
                // Date Range Section
                dateRangeSection

                // Category Section
                categorySection

                // Action Buttons
                actionButtonsSection
            }
            .navigationTitle("Filter")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                if let range = dateRange {
                    startDate = range.start
                    endDate = range.end
                    useDateRange = true
                }
            }
        }
    }

    // MARK: - Date Range Section

    private var dateRangeSection: some View {
        Section {
            Toggle("Filter by Date", isOn: $useDateRange)

            if useDateRange {
                DatePicker(
                    "Start Date",
                    selection: $startDate,
                    in: ...endDate,
                    displayedComponents: .date
                )

                DatePicker(
                    "End Date",
                    selection: $endDate,
                    in: startDate...,
                    displayedComponents: .date
                )
            }
        } header: {
            Text("Date Range")
        }
    }

    // MARK: - Category Section

    private var categorySection: some View {
        Section {
            ForEach(TransactionCategory.allCases, id: \.self) { category in
                HStack {
                    Image(systemName: category.icon)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .frame(width: 24)

                    Text(category.rawValue.capitalized)
                        .font(.body)

                    Spacer()

                    if selectedCategories.contains(category) {
                        Image(systemName: "checkmark")
                            .foregroundColor(.accentColor)
                            .font(.body.weight(.semibold))
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    if selectedCategories.contains(category) {
                        selectedCategories.remove(category)
                    } else {
                        selectedCategories.insert(category)
                    }
                }
            }
        } header: {
            Text("Categories")
        } footer: {
            if !selectedCategories.isEmpty {
                Text("\(selectedCategories.count) categories selected")
            }
        }
    }

    // MARK: - Action Buttons Section

    private var actionButtonsSection: some View {
        Section {
            Button {
                if useDateRange {
                    dateRange = (start: startDate, end: endDate)
                } else {
                    dateRange = nil
                }
                onApply()
            } label: {
                HStack {
                    Spacer()
                    Text("Apply Filters")
                        .fontWeight(.semibold)
                    Spacer()
                }
            }

            Button(role: .destructive) {
                onClear()
            } label: {
                HStack {
                    Spacer()
                    Text("Clear Filters")
                    Spacer()
                }
            }
        }
    }
}

// MARK: - Preview

#Preview("FilterSheetView - Empty") {
    FilterSheetView(
        selectedCategories: .constant([]),
        dateRange: .constant(nil),
        onApply: {},
        onClear: {}
    )
}

#Preview("FilterSheetView - With Filters") {
    FilterSheetView(
        selectedCategories: .constant([.purchase, .transfer]),
        dateRange: .constant((
            start: Date().addingTimeInterval(-7 * 24 * 60 * 60),
            end: Date()
        )),
        onApply: {},
        onClear: {}
    )
}
