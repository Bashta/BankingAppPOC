// SupportViewModel.swift
import Foundation
import Combine
final class SupportViewModel: ObservableObject {
    private weak var coordinator: MoreCoordinator?
    init(coordinator: MoreCoordinator) { self.coordinator = coordinator }
}
