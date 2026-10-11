import SwiftUI

/// Main entry point for the Authentication Application.
/// Handles root-level session routing between AuthView and HomeView.
@main
struct AuthApp: App {
    private let container = AppContainer.shared

    @State private var authenticatedUser: User? = nil
    @State private var isCheckingSession = true

    var body: some Scene {
        WindowGroup {
            ZStack {
                if isCheckingSession {
                    launchSplashView
                } else if let user = authenticatedUser {
                    HomeView(viewModel: containerHomeViewModel(user: user))
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .move(edge: .leading).combined(with: .opacity)
                        ))
                } else {
                    AuthView(viewModel: containerAuthViewModel())
                        .transition(.asymmetric(
                            insertion: .move(edge: .leading).combined(with: .opacity),
                            removal: .move(edge: .trailing).combined(with: .opacity)
                        ))
                }
            }
            .animation(.easeInOut(duration: 0.35), value: authenticatedUser)
            .task {
                await checkInitialSession()
            }
        }
    }

    // MARK: - Splash / Session Check
    private var launchSplashView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            Text("Checking Session...")
                .font(.footnote)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(uiColor: .systemGroupedBackground))
    }

    private func checkInitialSession() async {
        do {
            let user = try await container.makeGetCurrentUserUseCase().execute()
            self.authenticatedUser = user
        } catch {
            self.authenticatedUser = nil
        }
        self.isCheckingSession = false
    }

    // MARK: - Factory Helpers
    private func containerAuthViewModel() -> AuthViewModel {
        AuthViewModel(
            loginUseCase: container.makeLoginUseCase(),
            signupUseCase: container.makeSignupUseCase(),
            onAuthenticationSuccess: { user in
                self.authenticatedUser = user
            }
        )
    }

    private func containerHomeViewModel(user: User) -> HomeViewModel {
        HomeViewModel(
            getCurrentUserUseCase: container.makeGetCurrentUserUseCase(),
            logoutUseCase: container.makeLogoutUseCase(),
            authRepository: container.authRepository,
            initialUser: user,
            onLogout: {
                self.authenticatedUser = nil
            }
        )
    }
}
