import SwiftUI

@MainActor
public struct ResetPasswordRouteHostView: View {
    @StateObject private var viewModel: ResetPasswordViewModel

    private let onNavigateToLogin: () -> Void
    private let onShowToast: (String) -> Void
    private let onLoadingChanged: (Bool) -> Void

    public init(
        token: String,
        resetter: PasswordResetting = DemoPasswordResetter(),
        onNavigateToLogin: @escaping () -> Void,
        onShowToast: @escaping (String) -> Void,
        onLoadingChanged: @escaping (Bool) -> Void = { _ in }
    ) {
        _viewModel = StateObject(wrappedValue: ResetPasswordViewModel(token: token, resetter: resetter))
        self.onNavigateToLogin = onNavigateToLogin
        self.onShowToast = onShowToast
        self.onLoadingChanged = onLoadingChanged
    }

    public var body: some View {
        ResetPasswordScreen(
            state: viewModel.state,
            onEvent: viewModel.send
        )
        .onChange(of: viewModel.state.isLoading) { _, newValue in
            onLoadingChanged(newValue)
        }
        .task {
            for await effect in viewModel.effects {
                switch effect {
                case .navigateToLogin:
                    onNavigateToLogin()
                case .showToast(let message):
                    onShowToast(message)
                }
            }
        }
    }
}

#Preview("ResetPassword - Light") {
    ResetPasswordRouteHostView(
        token: "preview-token",
        resetter: DemoPasswordResetter(),
        onNavigateToLogin: {},
        onShowToast: { _ in }
    )
    .preferredColorScheme(.light)
}

#Preview("ResetPassword - Dark") {
    ResetPasswordRouteHostView(
        token: "preview-token",
        resetter: DemoPasswordResetter(),
        onNavigateToLogin: {},
        onShowToast: { _ in }
    )
    .preferredColorScheme(.dark)
}
