import Foundation

/// Data Transfer Object (DTO) for signup network request payload.
public struct SignupRequest: Codable, Equatable {
    public let name: String
    public let email: String
    public let password: String

    public init(name: String, email: String, password: String) {
        self.name = name
        self.email = email
        self.password = password
    }
}
