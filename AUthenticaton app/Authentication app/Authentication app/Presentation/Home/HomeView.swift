import SwiftUI

/// Dashboard screen shown to authenticated users.
/// Demonstrates the loaded Domain User model and Keychain token status.
public struct HomeView: View {
    @ObservedObject var viewModel: HomeViewModel
    @State private var showLogoutConfirmation = false

    public init(viewModel: HomeViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Profile Header Card
                    profileCard

                    // Security & Keychain Token Inspector
                    tokenInspectorCard

                    // LLD Architectural Insight Card
                    architectureOverviewCard

                    // Logout Action
                    logoutButtonSection
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 24)
            }
            .background(Color(uiColor: .systemGroupedBackground).ignoresSafeArea())
            .navigationTitle("Dashboard")
            .navigationBarTitleDisplayMode(.inline)
            .task {
                await viewModel.loadData()
            }
            .confirmationDialog(
                "Are you sure you want to log out?",
                isPresented: $showLogoutConfirmation,
                titleVisibility: .visible
            ) {
                Button("Log Out", role: .destructive) {
                    Task {
                        await viewModel.logout()
                    }
                }
                Button("Cancel", role: .cancel) {}
            }
        }
    }

    // MARK: - Subviews
    private var profileCard: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(LinearGradient(
                        colors: [.green, .teal],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 76, height: 76)
                    .shadow(color: .green.opacity(0.3), radius: 8, y: 4)

                Text(initials(for: viewModel.user?.name ?? "User"))
                    .font(.title2.bold())
                    .foregroundColor(.white)
            }

            VStack(spacing: 4) {
                Text(viewModel.user?.name ?? "Authenticated User")
                    .font(.title3.bold())

                Text(viewModel.user?.email ?? "email@example.com")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Text("ID: \(viewModel.user?.id ?? "N/A")")
                    .font(.caption2.monospaced())
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.secondary.opacity(0.12))
                    .cornerRadius(6)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .cornerRadius(18)
    }

    private var tokenInspectorCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label("Keychain Secure Storage", systemImage: "key.viewfinder")
                    .font(.headline)
                    .foregroundColor(.primary)
                Spacer()
                Text("Encrypted")
                    .font(.caption.bold())
                    .foregroundColor(.green)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.green.opacity(0.12))
                    .cornerRadius(6)
            }

            Divider()

            VStack(alignment: .leading, spacing: 10) {
                tokenRow(
                    title: "Access Token",
                    value: viewModel.tokens?.accessToken ?? "Not stored",
                    isMasked: true
                )

                tokenRow(
                    title: "Refresh Token",
                    value: viewModel.tokens?.refreshToken ?? "Not stored",
                    isMasked: true
                )

                HStack {
                    Text("Token Expiry:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    if let tokens = viewModel.tokens {
                        Text(tokens.expiresAt.formatted(date: .abbreviated, time: .shortened))
                            .font(.caption.monospaced())
                            .foregroundColor(tokens.isExpired ? .red : .primary)
                    } else {
                        Text("N/A")
                            .font(.caption.monospaced())
                    }
                }
            }
        }
        .padding(20)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .cornerRadius(18)
    }

    private func tokenRow(title: String, value: String, isMasked: Bool) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption.bold())
                .foregroundColor(.secondary)
            Text(isMasked && value.count > 16 ? "\(value.prefix(10))...\(value.suffix(6))" : value)
                .font(.caption.monospaced())
                .foregroundColor(.primary)
                .padding(8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(uiColor: .tertiarySystemGroupedBackground))
                .cornerRadius(8)
        }
    }

    private var architectureOverviewCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Clean Architecture Trace", systemImage: "arrow.triangle.swap")
                .font(.subheadline.bold())
                .foregroundColor(.primary)

            Text("Presentation (HomeViewModel) ➔ Domain (GetCurrentUserUseCase) ➔ Domain (AuthRepository) ➔ Data (DefaultAuthRepository) ➔ Core (KeychainService)")
                .font(.caption2)
                .foregroundColor(.secondary)
                .lineSpacing(3)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.blue.opacity(0.06))
        .cornerRadius(14)
    }

    private var logoutButtonSection: some View {
        Button(role: .destructive) {
            showLogoutConfirmation = true
        } label: {
            HStack {
                Image(systemName: "rectangle.portrait.and.arrow.right")
                Text("Log Out")
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(Color.red.opacity(0.1))
            .foregroundColor(.red)
            .cornerRadius(12)
        }
        .padding(.top, 8)
    }

    private func initials(for name: String) -> String {
        let parts = name.split(separator: " ")
        if let first = parts.first?.first {
            if parts.count > 1, let second = parts.last?.first {
                return "\(first)\(second)".uppercased()
            }
            return String(first).uppercased()
        }
        return "U"
    }
}

#Preview {
    let container = AppContainer.preview
    let viewModel = HomeViewModel(
        getCurrentUserUseCase: container.makeGetCurrentUserUseCase(),
        logoutUseCase: container.makeLogoutUseCase(),
        authRepository: container.authRepository,
        initialUser: User(id: "usr_123", email: "preview@test.com", name: "Preview User")
    )
    return HomeView(viewModel: viewModel)
}
