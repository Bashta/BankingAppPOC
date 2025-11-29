import Foundation
import LocalAuthentication
import OSLog

final class BiometricService: BiometricServiceProtocol {

    func canUseBiometrics() -> Bool {
        let context = LAContext()
        var error: NSError?
        let canEvaluate = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)

        if let error = error {
            Logger.biometric.debug("Biometrics not available: \(error.localizedDescription)")
        }

        Logger.biometric.debug("canUseBiometrics: \(canEvaluate)")
        return canEvaluate
    }

    func biometricType() -> BiometricType {
        let context = LAContext()
        guard canUseBiometrics() else {
            Logger.biometric.debug("biometricType: none (biometrics unavailable)")
            return .none
        }

        let type: BiometricType
        switch context.biometryType {
        case .faceID:
            type = .faceID
        case .touchID:
            type = .touchID
        default:
            type = .none
        }

        Logger.biometric.debug("biometricType: \(String(describing: type))")
        return type
    }

    func authenticate(reason: String) async throws -> Bool {
        Logger.biometric.info("Starting biometric authentication")
        let context = LAContext()
        context.localizedCancelTitle = "Use Password"

        do {
            let success = try await context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: reason
            )
            Logger.biometric.info("Biometric authentication succeeded")
            return success
        } catch let error as LAError {
            let biometricError = mapLAError(error)
            Logger.biometric.error("Biometric authentication failed: \(biometricError.userFriendlyMessage)")
            throw biometricError
        } catch {
            Logger.biometric.error("Biometric authentication unexpected error: \(error.localizedDescription)")
            throw BiometricError.authenticationFailed(error.localizedDescription)
        }
    }

    // MARK: - Private Helpers

    private func mapLAError(_ error: LAError) -> BiometricError {
        switch error.code {
        case .biometryNotAvailable:
            return .biometryNotAvailable
        case .biometryNotEnrolled:
            return .biometryNotEnrolled
        case .userCancel:
            return .userCancelled
        case .userFallback:
            return .userFallback
        case .authenticationFailed:
            return .authenticationFailed("Biometric authentication failed. Please try again.")
        case .biometryLockout:
            return .biometryLockout
        case .passcodeNotSet:
            return .passcodeNotSet
        case .systemCancel:
            return .systemCancelled
        default:
            return .authenticationFailed(error.localizedDescription)
        }
    }
}

// MARK: - Biometric Errors

enum BiometricError: LocalizedError, Equatable {
    case authenticationFailed(String)
    case biometryNotAvailable
    case biometryNotEnrolled
    case userCancelled
    case userFallback
    case biometryLockout
    case passcodeNotSet
    case systemCancelled

    /// User-friendly error message for display in UI
    var userFriendlyMessage: String {
        switch self {
        case .authenticationFailed(let message):
            return message
        case .biometryNotAvailable:
            return "Biometric authentication is not available on this device."
        case .biometryNotEnrolled:
            return "No biometric credentials are enrolled. Please set up Face ID or Touch ID in Settings."
        case .userCancelled:
            return "" // No message needed, user intentionally cancelled
        case .userFallback:
            return "" // User chose to use password
        case .biometryLockout:
            return "Biometric authentication is locked due to too many failed attempts. Please use your password."
        case .passcodeNotSet:
            return "Please set a passcode on your device to use biometric authentication."
        case .systemCancelled:
            return "Authentication was cancelled by the system. Please try again."
        }
    }

    var errorDescription: String? {
        userFriendlyMessage
    }

    /// Whether this error should show an alert to the user
    var shouldShowAlert: Bool {
        switch self {
        case .userCancelled, .userFallback:
            return false
        default:
            return true
        }
    }

    /// Whether the user should be offered a fallback to password
    var shouldOfferPasswordFallback: Bool {
        switch self {
        case .userFallback:
            return true // User explicitly requested fallback
        case .authenticationFailed, .biometryLockout:
            return true // Biometric failed, offer password
        default:
            return false
        }
    }
}
