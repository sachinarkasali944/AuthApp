import Foundation

/// DTO for the complete authentication response from the backend.
public struct AuthResponse: Codable {
    public let user: UserDTO
    public let tokens: TokensDTO

    public init(user: UserDTO, tokens: TokensDTO) {
        self.user = user
        self.tokens = tokens
    }
}

/// DTO for user received over the network.
public struct UserDTO: Codable {
    public let id: String
    public let email: String
    public let name: String
    public let createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case email
        case name
        case createdAt = "created_at"
    }

    public init(id: String, email: String, name: String, createdAt: Date? = nil) {
        self.id = id
        self.email = email
        self.name = name
        self.createdAt = createdAt
    }

    /// Maps network DTO to pure Domain Entity
    public func toDomain() -> User {
        return User(
            id: id,
            email: email,
            name: name,
            createdAt: createdAt
        )
    }
}

/// DTO for tokens received over the network.
public struct TokensDTO: Codable {
    public let accessToken: String
    public let refreshToken: String
    public let expiresInSeconds: Int

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case expiresInSeconds = "expires_in_seconds"
    }

    public init(accessToken: String, refreshToken: String, expiresInSeconds: Int = 3600) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.expiresInSeconds = expiresInSeconds
    }

    /// Maps network tokens DTO to pure Domain Entity with calculated expiration date
    public func toDomain() -> AuthTokens {
        let expiryDate = Date().addingTimeInterval(TimeInterval(expiresInSeconds))
        return AuthTokens(
            accessToken: accessToken,
            refreshToken: refreshToken,
            expiresAt: expiryDate
        )
    }
}
