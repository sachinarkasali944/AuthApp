import Foundation

/// Data Transfer Object (DTO) for login network request payload.
/// Decouples network API serialization details from Domain logic.
public struct LoginRequest: Codable, Equatable {
    public let email: String
    public let password: String

    public init(email: String, password: String) {
        self.email = email
        self.password = password
    }
}
