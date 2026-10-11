import Foundation

/// Pure Domain entity representing authentication credentials.
/// Securely stored via KeychainService and used for authenticated requests.
public struct AuthTokens: Equatable, Hashable, Codable {
    public let accessToken: String
    public let refreshToken: String
    public let expiresAt: Date

    public init(
        accessToken: String,
        refreshToken: String,
        expiresAt: Date
    ) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.expiresAt = expiresAt
    }

    /// Helper to check token freshness
    public var isExpired: Bool {
        return Date() >= expiresAt
    }
}
