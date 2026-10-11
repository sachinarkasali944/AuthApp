import Foundation

/// Contract for terminating an active user session.
public protocol LogoutUseCase {
    func execute() async throws
}

/// Default implementation of LogoutUseCase
public final class DefaultLogoutUseCase: LogoutUseCase {
    private let repository: AuthRepository

    public init(repository: AuthRepository) {
        self.repository = repository
    }

    public func execute() async throws {
        try await repository.logout()
    }
}
