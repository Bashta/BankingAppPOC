// AboutViewModel.swift
import Foundation
import Combine
final class AboutViewModel: ObservableObject {
    private weak var coordinator: MoreCoordinator?
    init(coordinator: MoreCoordinator) { self.coordinator = coordinator }
}
