import Combine
import Foundation

@MainActor
public final class LoginViewModel: ObservableObject {

    @Published public private(set) var state: LoginUiState

    // One-off events (navigation, alerts)
    public let effects: AsyncStream<LoginUiEffect>
    private let effectContinuation: AsyncStream<LoginUiEffect>.Continuation

    public init(initialState: LoginUiState? = nil) {
        self.state = initialState ?? LoginUiState()

        var cont: AsyncStream<LoginUiEffect>.Continuation!
        self.effects = AsyncStream<LoginUiEffect>(bufferingPolicy: .bufferingNewest(10)) { continuation in
            cont = continuation
        }
        self.effectContinuation = cont

        // Make sure state is consistent on init
        recalcDerivedState()
    }

    deinit {
        effectContinuation.finish()
    }

    public func onEvent(_ event: LoginUiEvent) {
        switch event {
        case .onAppear:
            // No business login yet
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

        case .forgotPasswordTapped:
            emit(.navigateForgotPassword)

        case .signUpTapped:
            emit(.navigateSignUp)

        case .loginTapped:
            // No firebase auth yet, Navigate placeholder for now.
            // Later this will call Firebase Auth / function then emit navigationHome.
            emit(.navigateHome)
        case .navigateForgotPassword:
            emit(.navigateForgotPassword)
        }
    }

    // MARK: - Private
    private func emit(_ effect: LoginUiEffect) {
        effectContinuation.yield(effect)
    }

    private func recalcDerivedState() {
        // Front-end only rule: enable if both are non-empty
        // Later:  replace with proper validation (email format, password rules, etc.)
        let emailOk = !state.email.trimmingCharacters(
            in: .whitespacesAndNewlines
        ).isEmpty
        let passwordOk = !state.password.trimmingCharacters(
            in: .whitespacesAndNewlines
        ).isEmpty
        state.isLoginEnabled = emailOk && passwordOk
    }
}
