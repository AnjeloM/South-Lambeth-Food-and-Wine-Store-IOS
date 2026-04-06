import Combine
import Foundation

@MainActor
public final class SignUpViewModel: ObservableObject {
    @Published public private(set) var state: SignUpUiState

    public let effects: AsyncStream<SignUpUiEffect>
    private let effectContinuation: AsyncStream<SignUpUiEffect>.Continuation

    public init(initialState: SignUpUiState? = nil) {
        self.state = initialState ?? SignUpUiState()

        var cont: AsyncStream<SignUpUiEffect>.Continuation!
        self.effects = AsyncStream(bufferingPolicy: .bufferingNewest(10)) {
            continuation in
            cont = continuation
        }
        self.effectContinuation = cont
    }

    deinit {
        effectContinuation.finish()
    }

    public func onEvent(_ event: SignUpUiEvent) {
        switch event {
        case .onAppear:
            break

        case .onbackTapped:
            emit(.navigateBack)

        case .nameChanged(let value):
            state.name = value

        case .emailChanged(let value):
            state.email = value

        case .passwordChanged(let value):
            state.password = value

        case .retypePasswordChanged(let value):
            state.retypePassword = value

        case .togglePasswordVisibility:
            state.isPasswordVisible.toggle()

        case .toggleRetypePasswordVisibility:
            state.isRetypePasswordVisible.toggle()

        case .googleTapped:
            emit(.continueWithGoogle)

        case .appleTapped:
            emit(.continueWithApple)

        case .privacyPolicyTapped:
            emit(.openURL(URL(string: "https://example.com/privacy")!))

        case .termsTapped:
            emit(.openURL(URL(string: "https://example.com/terms")!))
        }
    }

    private func emit(_ effect: SignUpUiEffect) {
        effectContinuation.yield(effect)
    }
}
