import SwiftUI

@MainActor
public struct LoginRouteHostView: View {
    @StateObject private var viewModel: LoginViewModel

    private let onNavigateBack: () -> Void
    private let onNavigateForgotPassword: () -> Void
    private let onNavigateSignUp: () -> Void
    private let onNavigateHome: () -> Void
    private let onShowToast: (String) -> Void

    public init(
        authenticator: LoginAuthenticating = DemoLoginAuthenticator(),
        onNavigateBack: @escaping () -> Void = {},
        onNavigateForgotPassword: @escaping () -> Void = {},
        onNavigateSignUp: @escaping () -> Void = {},
        onNavigateHome: @escaping () -> Void = {},
        onShowToast: @escaping (String) -> Void = { _ in }
    ) {
        _viewModel = StateObject(wrappedValue: LoginViewModel(authenticator: authenticator))
        self.onNavigateBack = onNavigateBack
        self.onNavigateForgotPassword = onNavigateForgotPassword
        self.onNavigateSignUp = onNavigateSignUp
        self.onNavigateHome = onNavigateHome
        self.onShowToast = onShowToast
    }

    public var body: some View {
        LoginScreen(
            state: viewModel.state,
            onEvent: viewModel.onEvent
        )
        .task {
            for await effect in viewModel.effects {
                handle(effect)
            }
        }
    }

    private func handle(_ effect: LoginUiEffect) {
        switch effect {
        case .navigateBack:
            onNavigateBack()

        case .navigateForgotPassword:
            onNavigateForgotPassword()

        case .navigateSignUp:
            onNavigateSignUp()

        case .navigateHome:
            onNavigateHome()

        case .showToast(let message):
            onShowToast(message)
        }
    }
}

#Preview("LoginRouteHostView") {
    LoginRouteHostView()
}
