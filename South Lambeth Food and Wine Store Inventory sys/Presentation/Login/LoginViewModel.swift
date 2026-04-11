import Combine
import Foundation

@MainActor
public final class LoginViewModel: ObservableObject {

    @Published public private(set) var state: LoginUiState

    public let effects: AsyncStream<LoginUiEffect>
    private let effectContinuation: AsyncStream<LoginUiEffect>.Continuation

    private let authenticator: LoginAuthenticating

    public init(
        initialState: LoginUiState? = nil,
        authenticator: LoginAuthenticating = DemoLoginAuthenticator()
    ) {
        self.state = initialState ?? LoginUiState()
        self.authenticator = authenticator

        var cont: AsyncStream<LoginUiEffect>.Continuation!
        self.effects = AsyncStream<LoginUiEffect>(bufferingPolicy: .bufferingNewest(10)) { continuation in
            cont = continuation
        }
        self.effectContinuation = cont

        recalcDerivedState()
    }

    deinit {
        effectContinuation.finish()
    }

    // MARK: - Events

    public func onEvent(_ event: LoginUiEvent) {
        switch event {
        case .onAppear:
            break

        case .onbackTapped:
            emit(.navigateBack)

        case .emailChanged(let value):
            state.email = value
            recalcDerivedState()

        case .passwordChanged(let value):
            state.password = value
            recalcDerivedState()

        case .passwordVisibilityTapped:
            state.isPasswordVisible.toggle()

        case .forgotPasswordTapped, .navigateForgotPassword:
            emit(.navigateForgotPassword)

        case .signUpTapped:
            emit(.navigateSignUp)

        case .loginTapped:
            Task { await signIn() }
        }
    }

    // MARK: - Sign In

    private func signIn() async {
        guard !state.isLoading else { return }

        let email    = state.email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let password = state.password.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !email.isEmpty, !password.isEmpty else { return }

        state.isLoading = true
        recalcDerivedState()

        do {
            try await authenticator.signIn(email: email, password: password)
            state.isLoading = false
            recalcDerivedState()
            emit(.navigateHome)
        } catch {
            state.isLoading = false
            recalcDerivedState()
            emit(.showToast(friendlyError(error)))
        }
    }

    // MARK: - Private

    private func recalcDerivedState() {
        let emailOk    = !state.email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let passwordOk = !state.password.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        state.isLoginEnabled = emailOk && passwordOk && !state.isLoading
    }

    private func friendlyError(_ error: Error) -> String {
        let message = error.localizedDescription.lowercased()
        if message.contains("password") || message.contains("credential") || message.contains("invalid") {
            return "Incorrect email or password. Please try again."
        }
        if message.contains("network") || message.contains("internet") {
            return "No internet connection. Please check your network."
        }
        if message.contains("too many") || message.contains("blocked") {
            return "Too many failed attempts. Please try again later."
        }
        return "Sign in failed. Please try again."
    }

    private func emit(_ effect: LoginUiEffect) {
        effectContinuation.yield(effect)
    }
}
