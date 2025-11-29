import Foundation

// MARK: - OTPPurpose Enum

enum OTPPurpose: String, Codable {
    case login
    case transfer
    case cardPINChange
    case passwordReset
}

// MARK: - AuthToken Model

struct AuthToken: Hashable, Codable {
    let accessToken: String
    let refreshToken: String?
    let expiresAt: Date
}

// MARK: - OTPReference Model

struct OTPReference: Hashable, Codable {
    let id: String
    let expiresAt: Date
    let purpose: OTPPurpose
}

// MARK: - LoginResult Model

struct LoginResult: Hashable, Codable {
    let token: AuthToken?
    let requiresOTP: Bool
    let otpReference: OTPReference?
}
