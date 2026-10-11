import SwiftUI

/// Authentication Screen supporting both Sign In and Sign Up modes.
public struct AuthView: View {
    @ObservedObject var viewModel: AuthViewModel
    @FocusState private var focusedField: Field?

    private enum Field {
        case name, email, password
    }

    public init(viewModel: AuthViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 28) {
                    // Header Branding
                    headerSection

                    // Mode Switcher (Sign In vs Sign Up)
                    modePickerSection

                    // Form Inputs Card
                    formCardSection

                    // Error Message Banner
                    if let error = viewModel.errorMessage {
                        errorBanner(message: error)
                    }

                    // Primary Action Button
                    actionButtonSection

                    // Quick Demo Fill Button (Convenient for LLD Interview Demos)
                    demoHelperSection
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 32)
            }
            .background(Color(uiColor: .systemGroupedBackground).ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    // MARK: - Subviews
    private var headerSection: some View {
        VStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(LinearGradient(
                        colors: [.blue, .indigo],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 80, height: 80)
                    .shadow(color: .blue.opacity(0.3), radius: 10, y: 5)

                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 38))
                    .foregroundColor(.white)
            }

            Text(viewModel.isSignUpMode ? "Create Account" : "Welcome Back")
                .font(.title2.bold())
                .foregroundColor(.primary)

            Text(viewModel.isSignUpMode ? "Sign up to get started" : "Sign in to access your dashboard")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(.top, 16)
    }

    private var modePickerSection: some View {
        Picker("Mode", selection: Binding(
            get: { viewModel.isSignUpMode },
            set: { _ in viewModel.toggleMode() }
        )) {
            Text("Sign In").tag(false)
            Text("Sign Up").tag(true)
        }
        .pickerStyle(.segmented)
    }

    private var formCardSection: some View {
        VStack(spacing: 16) {
            if viewModel.isSignUpMode {
                HStack {
                    Image(systemName: "person.fill")
                        .foregroundColor(.secondary)
                        .frame(width: 24)
                    TextField("Full Name", text: $viewModel.name)
                        .textContentType(.name)
                        .focused($focusedField, equals: .name)
                        .submitLabel(.next)
                        .onSubmit { focusedField = .email }
                }
                .padding()
                .background(Color(uiColor: .secondarySystemGroupedBackground))
                .cornerRadius(12)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }

            HStack {
                Image(systemName: "envelope.fill")
                    .foregroundColor(.secondary)
                    .frame(width: 24)
                TextField("Email Address", text: $viewModel.email)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .textContentType(.emailAddress)
                    .focused($focusedField, equals: .email)
                    .submitLabel(.next)
                    .onSubmit { focusedField = .password }
            }
            .padding()
            .background(Color(uiColor: .secondarySystemGroupedBackground))
            .cornerRadius(12)

            HStack {
                Image(systemName: "key.fill")
                    .foregroundColor(.secondary)
                    .frame(width: 24)
                SecureField("Password (min 6 characters)", text: $viewModel.password)
                    .textContentType(viewModel.isSignUpMode ? .newPassword : .password)
                    .focused($focusedField, equals: .password)
                    .submitLabel(.done)
                    .onSubmit {
                        Task { await viewModel.submit() }
                    }
            }
            .padding()
            .background(Color(uiColor: .secondarySystemGroupedBackground))
            .cornerRadius(12)
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: viewModel.isSignUpMode)
    }

    private func errorBanner(message: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.red)
            Text(message)
                .font(.footnote)
                .foregroundColor(.red)
            Spacer()
        }
        .padding()
        .background(Color.red.opacity(0.1))
        .cornerRadius(10)
    }

    private var actionButtonSection: some View {
        Button {
            focusedField = nil
            Task {
                await viewModel.submit()
            }
        } label: {
            ZStack {
                if viewModel.isLoading {
                    ProgressView()
                        .tint(.white)
                } else {
                    Text(viewModel.isSignUpMode ? "Create Account" : "Sign In")
                        .font(.headline)
                        .foregroundColor(.white)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(LinearGradient(
                colors: [.blue, .indigo],
                startPoint: .leading,
                endPoint: .trailing
            ))
            .cornerRadius(14)
            .shadow(color: .blue.opacity(0.3), radius: 8, y: 4)
        }
        .disabled(viewModel.isLoading)
    }

    private var demoHelperSection: some View {
        Button {
            viewModel.email = "alex.dev@example.com"
            viewModel.password = "password123"
            if viewModel.isSignUpMode {
                viewModel.name = "Alex Developer"
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "wand.and.stars")
                Text("Fill Demo Credentials")
            }
            .font(.footnote)
            .foregroundColor(.secondary)
        }
        .padding(.top, 8)
    }
}

#Preview {
    let container = AppContainer.preview
    let viewModel = AuthViewModel(
        loginUseCase: container.makeLoginUseCase(),
        signupUseCase: container.makeSignupUseCase()
    )
    return AuthView(viewModel: viewModel)
}
