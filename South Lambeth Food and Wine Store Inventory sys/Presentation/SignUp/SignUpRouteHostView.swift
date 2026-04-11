import SwiftUI

@MainActor
public struct SignUpRouteHostView: View {
    @StateObject private var viewModel: SignUpViewModel

    private let onNavigateBack: () -> Void
    private let onOpenURL: (URL) -> Void
    private let onNavigateOtp: (String, String, String) -> Void
    private let onContinueWithGoogle: () -> Void
    private let onContinueWithApple: () -> Void
    private let onLoadingChanged: (Bool) -> Void

    @State private var toastMessage: String?
    @State private var isToastPresented: Bool = false

    public init(
        otpSender: SignUpOtpSending = DemoSignUpOtpSender(),
        onNavigateBack: @escaping () -> Void,
        onOpenURL: @escaping (URL) -> Void,
        onNavigateOtp: @escaping (String, String, String) -> Void,
        onContinueWithGoogle: @escaping () -> Void,
        onContinueWithApple: @escaping () -> Void,
        onLoadingChanged: @escaping (Bool) -> Void = { _ in }
    ) {
        _viewModel = StateObject(wrappedValue: SignUpViewModel(otpSender: otpSender))
        self.onNavigateBack = onNavigateBack
        self.onOpenURL = onOpenURL
        self.onNavigateOtp = onNavigateOtp
        self.onContinueWithGoogle = onContinueWithGoogle
        self.onContinueWithApple = onContinueWithApple
        self.onLoadingChanged = onLoadingChanged
    }

    public var body: some View {
        SignUpScreen(state: viewModel.state, onEvent: viewModel.onEvent)
            .onChange(of: viewModel.state.isLoading) { _, newValue in
                onLoadingChanged(newValue)
            }
            .alert("Notice", isPresented: $isToastPresented) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(toastMessage ?? "")
            }
            .task {
                for await effect in viewModel.effects {
                    switch effect {
                    case .navigateBack:
                        onNavigateBack()
                    case .openURL(let url):
                        onOpenURL(url)
                    case .navigateToOtp(let email, let name, let password):
                        onNavigateOtp(email, name, password)
                    case .continueWithGoogle:
                        onContinueWithGoogle()
                    case .continueWithApple:
                        onContinueWithApple()
                    case .showToast(let message):
                        toastMessage = message
                        isToastPresented = true
                    }
                }
            }
    }
}

// MARK: - Previews

#Preview("SignUpRouteHostView - Light") {
    SignUpRouteHostView(
        otpSender: DemoSignUpOtpSender(),
        onNavigateBack: {},
        onOpenURL: { _ in },
        onNavigateOtp: { _, _, _ in },
        onContinueWithGoogle: {},
        onContinueWithApple: {}
    )
    .preferredColorScheme(.light)
}

#Preview("SignUpRouteHostView - Dark") {
    SignUpRouteHostView(
        otpSender: DemoSignUpOtpSender(),
        onNavigateBack: {},
        onOpenURL: { _ in },
        onNavigateOtp: { _, _, _ in },
        onContinueWithGoogle: {},
        onContinueWithApple: {}
    )
    .preferredColorScheme(.dark)
}
