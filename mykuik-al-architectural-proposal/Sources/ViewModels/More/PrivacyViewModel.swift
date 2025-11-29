// PrivacyViewModel.swift
import Foundation
import Combine
final class PrivacyViewModel: ObservableObject {
    private weak var coordinator: MoreCoordinator?
    init(coordinator: MoreCoordinator) { self.coordinator = coordinator }
}
