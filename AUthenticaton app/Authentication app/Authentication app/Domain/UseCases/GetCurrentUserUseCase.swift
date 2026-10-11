import Foundation

/// Contract for fetching currently authenticated user.
public protocol GetCurrentUserUseCase {
    func execute() async throws -> User?
}

/// Default implementation of GetCurrentUserUseCase
public final class DefaultGetCurrentUserUseCase: GetCurrentUserUseCase {
    private let repository: AuthRepository

    public init(repository: AuthRepository) {
        self.repository = repository
    }

    public func execute() async throws -> User? {
        return try await repository.getCurrentUser()
    }
}
