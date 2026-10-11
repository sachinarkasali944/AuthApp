import XCTest
@testable import Authentication_app

// MARK: - Mock Repository for Testing
final class MockAuthRepository: AuthRepository {
    var loginResult: Result<(user: User, tokens: AuthTokens), Error>?
    var signupResult: Result<(user: User, tokens: AuthTokens), Error>?
    var currentUserResult: User?
    var storedTokensResult: AuthTokens?
    var logoutCalled = false

    func login(email: String, password: String) async throws -> (user: User, tokens: AuthTokens) {
        switch loginResult {
        case .success(let data): return data
        case .failure(let error): throw error
        case .none:
            return (
                User(id: "usr_mock", email: email, name: "Mock User"),
                AuthTokens(accessToken: "mock_tok", refreshToken: "mock_ref", expiresAt: Date().addingTimeInterval(3600))
            )
        }
    }

    func signup(name: String, email: String, password: String) async throws -> (user: User, tokens: AuthTokens) {
        switch signupResult {
        case .success(let data): return data
        case .failure(let error): throw error
        case .none:
            return (
                User(id: "usr_mock_new", email: email, name: name),
                AuthTokens(accessToken: "mock_tok", refreshToken: "mock_ref", expiresAt: Date().addingTimeInterval(3600))
            )
        }
    }

    func getCurrentUser() async throws -> User? {
        return currentUserResult
    }

    func getStoredTokens() async throws -> AuthTokens? {
        return storedTokensResult
    }

    func logout() async throws {
        logoutCalled = true
    }
}

// MARK: - Unit Tests
final class Authentication_appTests: XCTestCase {

    func test_loginUseCase_withEmptyEmail_throwsEmptyFieldsError() async {
        let mockRepo = MockAuthRepository()
        let useCase = DefaultLoginUseCase(repository: mockRepo)

        do {
            _ = try await useCase.execute(email: "", password: "password123")
            XCTFail("Expected emptyFields error, but succeeded.")
        } catch let error as AuthError {
            XCTAssertEqual(error, .emptyFields)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func test_loginUseCase_withInvalidEmailFormat_throwsInvalidEmailError() async {
        let mockRepo = MockAuthRepository()
        let useCase = DefaultLoginUseCase(repository: mockRepo)

        do {
            _ = try await useCase.execute(email: "notanemail", password: "password123")
            XCTFail("Expected invalidEmail error, but succeeded.")
        } catch let error as AuthError {
            XCTAssertEqual(error, .invalidEmail)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func test_loginUseCase_withShortPassword_throwsPasswordTooShortError() async {
        let mockRepo = MockAuthRepository()
        let useCase = DefaultLoginUseCase(repository: mockRepo)

        do {
            _ = try await useCase.execute(email: "valid@email.com", password: "123")
            XCTFail("Expected passwordTooShort error, but succeeded.")
        } catch let error as AuthError {
            XCTAssertEqual(error, .passwordTooShort(min: 6))
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func test_loginUseCase_withValidCredentials_returnsUser() async throws {
        let mockRepo = MockAuthRepository()
        let expectedUser = User(id: "usr_100", email: "user@test.com", name: "Test User")
        mockRepo.loginResult = .success((
            user: expectedUser,
            tokens: AuthTokens(accessToken: "a", refreshToken: "b", expiresAt: Date().addingTimeInterval(1000))
        ))

        let useCase = DefaultLoginUseCase(repository: mockRepo)
        let result = try await useCase.execute(email: "user@test.com", password: "password123")

        XCTAssertEqual(result.id, expectedUser.id)
        XCTAssertEqual(result.email, expectedUser.email)
    }

    func test_logoutUseCase_callsRepositoryLogout() async throws {
        let mockRepo = MockAuthRepository()
        let useCase = DefaultLogoutUseCase(repository: mockRepo)

        try await useCase.execute()

        XCTAssertTrue(mockRepo.logoutCalled)
    }

    @MainActor
    func test_authViewModel_submittingValidInput_setsCurrentUser() async {
        let mockRepo = MockAuthRepository()
        let loginUseCase = DefaultLoginUseCase(repository: mockRepo)
        let signupUseCase = DefaultSignupUseCase(repository: mockRepo)

        let viewModel = AuthViewModel(
            loginUseCase: loginUseCase,
            signupUseCase: signupUseCase
        )

        viewModel.email = "alex@test.com"
        viewModel.password = "password123"

        await viewModel.submit()

        XCTAssertNotNil(viewModel.currentUser)
        XCTAssertEqual(viewModel.currentUser?.email, "alex@test.com")
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertFalse(viewModel.isLoading)
    }
}
