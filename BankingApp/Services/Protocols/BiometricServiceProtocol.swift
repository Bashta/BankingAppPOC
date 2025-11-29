import Foundation

enum BiometricType {
    case faceID
    case touchID
    case none
}

protocol BiometricServiceProtocol {
    func canUseBiometrics() -> Bool
    func biometricType() -> BiometricType
    func authenticate(reason: String) async throws -> Bool
}
