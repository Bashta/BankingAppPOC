//
//  StatementView.swift
//  BankingApp
//
//  Statement download view for selecting month/year and generating account statements.
//

import SwiftUI

struct StatementView: View {
    @ObservedObject var viewModel: StatementViewModel
    @State private var showShareSheet = false

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Account Info Card
                if let account = viewModel.account {
                    accountInfoCard(account: account)
                }

                // Date Selection Section
                dateSelectionSection

                // Generate Button
                generateButton

                // Share Button (appears after generation)
                if viewModel.downloadURL != nil {
                    shareButton
                }

                // Error Display
                if let error = viewModel.error {
                    errorView(error: error)
                }
            }
            .padding()
        }
        .navigationTitle("Account Statement")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.loadAccount()
        }
        .sheet(isPresented: $showShareSheet) {
            if let url = viewModel.downloadURL {
                ActivityViewController(activityItems: [url])
            }
        }
    }

    // MARK: - Account Info Card

    private func accountInfoCard(account: Account) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(account.accountName)
                .font(.headline)

            HStack {
                Text(account.accountType.displayName)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.secondary.opacity(0.15))
                    .foregroundColor(.secondary)
                    .cornerRadius(4)

                Text(account.accountNumber.maskedAccountNumber)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }

    // MARK: - Date Selection Section

    private var dateSelectionSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Select Period")
                .font(.headline)

            HStack {
                // Month Picker
                VStack(alignment: .leading, spacing: 4) {
                    Text("Month")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Picker("Month", selection: $viewModel.selectedMonth) {
                        ForEach(1...12, id: \.self) { month in
                            Text(viewModel.monthNames[month - 1]).tag(month)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                Spacer()

                // Year Picker
                VStack(alignment: .leading, spacing: 4) {
                    Text("Year")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Picker("Year", selection: $viewModel.selectedYear) {
                        ForEach(viewModel.availableYears, id: \.self) { year in
                            Text(String(year)).tag(year)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }

            // Invalid selection warning
            if !viewModel.isValidSelection {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    Text("Cannot select future dates")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }

    // MARK: - Generate Button

    private var generateButton: some View {
        Button(action: {
            Task {
                await viewModel.generateStatement()
            }
        }) {
            HStack {
                if viewModel.isGenerating {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    Text("Generating...")
                } else {
                    Image(systemName: "doc.text")
                    Text("Generate Statement")
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(viewModel.isValidSelection && !viewModel.isGenerating ? Color.blue : Color.gray)
            .foregroundColor(.white)
            .cornerRadius(12)
        }
        .disabled(!viewModel.isValidSelection || viewModel.isGenerating)
    }

    // MARK: - Share Button

    private var shareButton: some View {
        Button(action: {
            viewModel.shareStatement()
            showShareSheet = true
        }) {
            HStack {
                Image(systemName: "square.and.arrow.up")
                Text("Share Statement")
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.green)
            .foregroundColor(.white)
            .cornerRadius(12)
        }
    }

    // MARK: - Error View

    private func errorView(error: Error) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundColor(.red)

            Text(error.localizedDescription)
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)

            Button("Try Again") {
                Task {
                    await viewModel.generateStatement()
                }
            }
            .buttonStyle(.bordered)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}
