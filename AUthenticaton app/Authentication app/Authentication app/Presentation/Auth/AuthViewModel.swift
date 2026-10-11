import Foundation
import Combine

/// ViewModel managing state and user actions for Login and Signup flows.
/// Runs on MainActor to safely update UI state.
@MainActor
public final class AuthViewModel: ObservableObject {
    // MARK: - Input State
    @Published public var name: String = ""
    @Published public var email: String = ""
    @Published public var password: String = ""
    @Published public var isSignUpMode: Bool = false

    // MARK: - UI State
    @Published public var isLoading: Bool = false
    @Published public var errorMessage: String? = nil
    @Published public var currentUser: User? = nil

    // MARK: - Dependencies (UseCases)
    private let loginUseCase: LoginUseCase
    private let signupUseCase: SignupUseCase
    private let onAuthenticationSuccess: ((User) -> Void)?

    public init(
        loginUseCase: LoginUseCase,
        signupUseCase: SignupUseCase,
        onAuthenticationSuccess: ((User) -> Void)? = nil
    ) {
        self.loginUseCase = loginUseCase
        self.signupUseCase = signupUseCase
        self.onAuthenticationSuccess = onAuthenticationSuccess
    }

    // MARK: - Actions
    public func toggleMode() {
        isSignUpMode.toggle()
        errorMessage = nil
    }

    public func submit() async {
        errorMessage = nil
        isLoading = true
        defer { isLoading = false }

        do {
            let user: User
            if isSignUpMode {
                user = try await signupUseCase.execute(
                    name: name,
                    email: email,
                    password: password
                )
            } else {
                user = try await loginUseCase.execute(
                    email: email,
                    password: password
                )
            }

            self.currentUser = user
            self.onAuthenticationSuccess?(user)
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }
}
