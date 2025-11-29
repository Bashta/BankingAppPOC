// OTPViewModel.swift
import Foundation
import Combine
final class OTPViewModel: ObservableObject {
    private let otpReference: OTPReference
    private let authService: AuthServiceProtocol
    private weak var coordinator: AuthCoordinator?
    init(otpReference: OTPReference, authService: AuthServiceProtocol, coordinator: AuthCoordinator) {
        self.otpReference = otpReference
        self.authService = authService
        self.coordinator = coordinator
    }
}
