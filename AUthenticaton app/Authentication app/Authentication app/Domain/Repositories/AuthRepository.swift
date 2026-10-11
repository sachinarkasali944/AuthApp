import Foundation

/// Domain-level contract for Authentication operations.
/// Follows the Dependency Inversion Principle (DIP):
/// High-level domain logic depends on this abstraction, not on concrete network or database implementations.
public protocol AuthRepository {
    /// Authenticates a user with email and password
    func login(email: String, password: String) async throws -> (user: User, tokens: AuthTokens)

    /// Registers a new user account
    func signup(name: String, email: String, password: String) async throws -> (user: User, tokens: AuthTokens)

    /// Retrieves currently authenticated user session if present
    func getCurrentUser() async throws -> User?

    /// Retrieves stored authentication tokens
    func getStoredTokens() async throws -> AuthTokens?

    /// Logs out user, invalidating session and clearing secure storage
    func logout() async throws
}
