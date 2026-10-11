import Foundation

/// Business error domain for authentication operations.
public enum AuthError: LocalizedError, Equatable {
    case emptyFields
    case invalidEmail
    case passwordTooShort(min: Int)
    case unauthenticated
    case custom(String)

    public var errorDescription: String? {
        switch self {
        case .emptyFields:
            return "Please fill in all required fields."
        case .invalidEmail:
            return "Please enter a valid email address."
        case .passwordTooShort(let min):
            return "Password must be at least \(min) characters."
        case .unauthenticated:
            return "User is not logged in."
        case .custom(let message):
            return message
        }
    }
}

/// Contract for logging in a user.
/// Adheres to Single Responsibility Principle (SRP): handles only Login business logic.
public protocol LoginUseCase {
    func execute(email: String, password: String) async throws -> User
}

/// Default implementation of LoginUseCase
public final class DefaultLoginUseCase: LoginUseCase {
    private let repository: AuthRepository

    public init(repository: AuthRepository) {
        self.repository = repository
    }

    public func execute(email: String, password: String) async throws -> User {
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedEmail.isEmpty, !password.isEmpty else {
            throw AuthError.emptyFields
        }

        guard isValidEmail(trimmedEmail) else {
            throw AuthError.invalidEmail
        }

        guard password.count >= 6 else {
            throw AuthError.passwordTooShort(min: 6)
        }

        let result = try await repository.login(email: trimmedEmail, password: password)
        return result.user
    }

    private func isValidEmail(_ email: String) -> Bool {
        let pattern = #"^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,64}$"#
        return email.range(of: pattern, options: .regularExpression) != nil
    }
}
