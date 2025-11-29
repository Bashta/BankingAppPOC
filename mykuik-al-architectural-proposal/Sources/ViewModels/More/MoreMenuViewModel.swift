// MoreMenuViewModel.swift
import Foundation
import Combine
final class MoreMenuViewModel: ObservableObject {
    private weak var coordinator: MoreCoordinator?
    init(coordinator: MoreCoordinator) { self.coordinator = coordinator }
}
