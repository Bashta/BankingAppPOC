import Foundation

// MARK: - Address Model

struct Address: Hashable, Codable {
    let street: String
    let city: String
    let state: String
    let zipCode: String
    let country: String
}

// MARK: - User Model

struct User: Identifiable, Hashable, Codable {
    let id: String
    let username: String
    let name: String
    let email: String
    let phoneNumber: String
    let address: Address?
}
