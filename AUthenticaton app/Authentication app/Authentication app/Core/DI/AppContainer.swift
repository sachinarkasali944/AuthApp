import Foundation
import SwiftUI

/// Abstract contract for Dependency Injection Container.
/// Guarantees that any consumer depends on abstractions, enabling mock containers for testing.
public protocol AppContainerProtocol {
    var apiClient: APIClient { get }
    var keychainService: KeychainService { get }
    var authRepository: AuthRepository { get }

    // Use Case Factories
    func makeLoginUseCase() -> LoginUseCase
    func makeSignupUseCase() -> SignupUseCase
    func makeGetCurrentUserUseCase() -> GetCurrentUserUseCase
    func makeLogoutUseCase() -> LogoutUseCase
}

/// Central Dependency Injection (DI) Container.
/// Acts as the Composition Root of the application.
/// Follows the Factory and Dependency Inversion patterns.
public final class AppContainer: AppContainerProtocol {
    public static let shared = AppContainer()

    // MARK: - Core Services (Singletons in container scope)
    public let apiClient: APIClient
    public let keychainService: KeychainService
    public let authRepository: AuthRepository

    public init(
        apiClient: APIClient = URLSessionAPIClient(isMockMode: true),
        keychainService: KeychainService = DefaultKeychainService()
    ) {
        self.apiClient = apiClient
        self.keychainService = keychainService
        self.authRepository = DefaultAuthRepository(
            apiClient: apiClient,
            keychain: keychainService
        )
    }

    // MARK: - UseCase Factories
    public func makeLoginUseCase() -> LoginUseCase {
        return DefaultLoginUseCase(repository: authRepository)
    }

    public func makeSignupUseCase() -> SignupUseCase {
        return DefaultSignupUseCase(repository: authRepository)
    }

    public func makeGetCurrentUserUseCase() -> GetCurrentUserUseCase {
        return DefaultGetCurrentUserUseCase(repository: authRepository)
    }

    public func makeLogoutUseCase() -> LogoutUseCase {
        return DefaultLogoutUseCase(repository: authRepository)
    }

    // MARK: - Preview / Testing Helper
    public static var preview: AppContainer {
        return AppContainer(
            apiClient: URLSessionAPIClient(isMockMode: true),
            keychainService: DefaultKeychainService(serviceName: "com.authapp.preview")
        )
    }
}
