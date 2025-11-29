import Foundation
import LocalAuthentication

final class BiometricService: BiometricServiceProtocol {
    func canUseBiometrics() -> Bool {
        let context = LAContext()
        var error: NSError?
        return context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
    }

    func biometricType() -> BiometricType {
        let context = LAContext()
        guard canUseBiometrics() else { return .none }

        switch context.biometryType {
        case .faceID:
            return .faceID
        case .touchID:
            return .touchID
        default:
            return .none
        }
    }

    func authenticate(reason: String) async throws -> Bool {
        let context = LAContext()

        do {
            let success = try await context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: reason
            )
            return success
        } catch {
            throw BiometricError.authenticationFailed(error.localizedDescription)
        }
    }
}

enum BiometricError: Error {
    case authenticationFailed(String)
    case biometricsNotAvailable
}
