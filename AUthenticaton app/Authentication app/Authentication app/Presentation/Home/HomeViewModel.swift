import Foundation
import Combine

/// ViewModel managing the authenticated Home/Dashboard screen.
@MainActor
public final class HomeViewModel: ObservableObject {
    // MARK: - State
    @Published public var user: User?
    @Published public var tokens: AuthTokens?
    @Published public var isLoading: Bool = false
    @Published public var errorMessage: String? = nil

    // MARK: - Dependencies
    private let getCurrentUserUseCase: GetCurrentUserUseCase
    private let logoutUseCase: LogoutUseCase
    private let authRepository: AuthRepository
    private let onLogout: (() -> Void)?

    public init(
        getCurrentUserUseCase: GetCurrentUserUseCase,
        logoutUseCase: LogoutUseCase,
        authRepository: AuthRepository,
        initialUser: User? = nil,
        onLogout: (() -> Void)? = nil
    ) {
        self.getCurrentUserUseCase = getCurrentUserUseCase
        self.logoutUseCase = logoutUseCase
        self.authRepository = authRepository
        self.user = initialUser
        self.onLogout = onLogout
    }

    // MARK: - Actions
    public func loadData() async {
        isLoading = true
        defer { isLoading = false }

        do {
            if user == nil {
                self.user = try await getCurrentUserUseCase.execute()
            }
            self.tokens = try await authRepository.getStoredTokens()
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }

    public func logout() async {
        isLoading = true
        defer { isLoading = false }

        do {
            try await logoutUseCase.execute()
            self.user = nil
            self.tokens = nil
            self.onLogout?()
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }
}
