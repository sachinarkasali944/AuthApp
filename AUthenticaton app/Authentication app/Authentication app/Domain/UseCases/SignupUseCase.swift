import Foundation

/// Contract for signing up a new user.
/// Adheres to Single Responsibility Principle (SRP): handles only Registration business logic.
public protocol SignupUseCase {
    func execute(name: String, email: String, password: String) async throws -> User
}

/// Default implementation of SignupUseCase
public final class DefaultSignupUseCase: SignupUseCase {
    private let repository: AuthRepository

    public init(repository: AuthRepository) {
        self.repository = repository
    }

    public func execute(name: String, email: String, password: String) async throws -> User {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedName.isEmpty, !trimmedEmail.isEmpty, !password.isEmpty else {
            throw AuthError.emptyFields
        }

        guard isValidEmail(trimmedEmail) else {
            throw AuthError.invalidEmail
        }

        guard password.count >= 6 else {
            throw AuthError.passwordTooShort(min: 6)
        }

        let result = try await repository.signup(name: trimmedName, email: trimmedEmail, password: password)
        return result.user
    }

    private func isValidEmail(_ email: String) -> Bool {
        let pattern = #"^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,64}$"#
        return email.range(of: pattern, options: .regularExpression) != nil
    }
}
