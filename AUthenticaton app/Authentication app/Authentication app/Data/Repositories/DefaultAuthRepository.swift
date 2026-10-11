import Foundation

/// Internal struct representing auth network endpoints
private struct AuthEndpoint: Endpoint {
    var path: String
    var method: HTTPMethod
    var headers: [String: String]?
    var body: Data?
    var queryItems: [URLQueryItem]?
}

/// Concrete implementation of AuthRepository.
/// Coordinates between Network APIClient and Keychain Storage.
/// Acts as the single source of truth for Authentication data.
public final class DefaultAuthRepository: AuthRepository {
    private let apiClient: APIClient
    private let keychain: KeychainService

    // In-memory cache for fast access
    private var cachedUser: User?

    // Keychain Keys
    private let accessTokenKey = "auth_access_token"
    private let refreshTokenKey = "auth_refresh_token"
    private let tokenExpiryKey = "auth_token_expiry"
    private let cachedUserKey = "auth_cached_user"

    public init(
        apiClient: APIClient,
        keychain: KeychainService
    ) {
        self.apiClient = apiClient
        self.keychain = keychain
    }

    // MARK: - Login
    public func login(email: String, password: String) async throws -> (user: User, tokens: AuthTokens) {
        let requestDTO = LoginRequest(email: email, password: password)
        let bodyData = try JSONEncoder().encode(requestDTO)

        let endpoint = AuthEndpoint(
            path: "/auth/login",
            method: .post,
            headers: ["Content-Type": "application/json"],
            body: bodyData
        )

        let response: AuthResponse = try await apiClient.request(endpoint: endpoint)
        let user = response.user.toDomain()
        let tokens = response.tokens.toDomain()

        try persistSession(user: user, tokens: tokens)
        self.cachedUser = user

        return (user, tokens)
    }

    // MARK: - Signup
    public func signup(name: String, email: String, password: String) async throws -> (user: User, tokens: AuthTokens) {
        let requestDTO = SignupRequest(name: name, email: email, password: password)
        let bodyData = try JSONEncoder().encode(requestDTO)

        let endpoint = AuthEndpoint(
            path: "/auth/signup",
            method: .post,
            headers: ["Content-Type": "application/json"],
            body: bodyData
        )

        let response: AuthResponse = try await apiClient.request(endpoint: endpoint)
        let user = response.user.toDomain()
        let tokens = response.tokens.toDomain()

        try persistSession(user: user, tokens: tokens)
        self.cachedUser = user

        return (user, tokens)
    }

    // MARK: - Get Current User
    public func getCurrentUser() async throws -> User? {
        // Return memory cached user if available
        if let cached = cachedUser {
            return cached
        }

        // Try reading cached user from Keychain
        if let userData = try keychain.get(key: cachedUserKey),
           let user = try? JSONDecoder().decode(User.self, from: userData) {
            self.cachedUser = user
            return user
        }

        // If tokens exist, attempt fetching profile from backend
        guard let tokens = try await getStoredTokens(), !tokens.isExpired else {
            return nil
        }

        let endpoint = AuthEndpoint(
            path: "/auth/me",
            method: .get,
            headers: [
                "Authorization": "Bearer \(tokens.accessToken)",
                "Content-Type": "application/json"
            ]
        )

        do {
            let response: AuthResponse = try await apiClient.request(endpoint: endpoint)
            let user = response.user.toDomain()
            self.cachedUser = user
            if let encodedUser = try? JSONEncoder().encode(user) {
                try? keychain.save(key: cachedUserKey, data: encodedUser)
            }
            return user
        } catch {
            return nil
        }
    }

    // MARK: - Get Stored Tokens
    public func getStoredTokens() async throws -> AuthTokens? {
        guard let accessToken = try keychain.getString(key: accessTokenKey),
              let refreshToken = try keychain.getString(key: refreshTokenKey),
              let expiryString = try keychain.getString(key: tokenExpiryKey),
              let timeInterval = Double(expiryString) else {
            return nil
        }

        return AuthTokens(
            accessToken: accessToken,
            refreshToken: refreshToken,
            expiresAt: Date(timeIntervalSince1970: timeInterval)
        )
    }

    // MARK: - Logout
    public func logout() async throws {
        cachedUser = nil
        try? keychain.delete(key: accessTokenKey)
        try? keychain.delete(key: refreshTokenKey)
        try? keychain.delete(key: tokenExpiryKey)
        try? keychain.delete(key: cachedUserKey)
    }

    // MARK: - Private Session Persistence Helper
    private func persistSession(user: User, tokens: AuthTokens) throws {
        try keychain.saveString(key: accessTokenKey, value: tokens.accessToken)
        try keychain.saveString(key: refreshTokenKey, value: tokens.refreshToken)
        try keychain.saveString(key: tokenExpiryKey, value: String(tokens.expiresAt.timeIntervalSince1970))

        if let userData = try? JSONEncoder().encode(user) {
            try keychain.save(key: cachedUserKey, data: userData)
        }
    }
}
