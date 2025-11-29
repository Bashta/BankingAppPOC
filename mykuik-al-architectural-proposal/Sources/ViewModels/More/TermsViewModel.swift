// TermsViewModel.swift
import Foundation
import Combine
final class TermsViewModel: ObservableObject {
    private weak var coordinator: MoreCoordinator?
    init(coordinator: MoreCoordinator) { self.coordinator = coordinator }
}
