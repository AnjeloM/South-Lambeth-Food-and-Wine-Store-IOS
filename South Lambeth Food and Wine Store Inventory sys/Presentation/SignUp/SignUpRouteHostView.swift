import SwiftUI

@MainActor
public struct SignUpRouteHostView: View {
    @StateObject private var viewModel: SignUpViewModel

    private let onNavigateBack: () -> Void
    private let onOpenURL: (URL) -> Void
    private let onContinueWithGoogle: () -> Void
    private let onContinueWithApple: () -> Void

    public init(
        viewModel: SignUpViewModel? = nil,
        onNavigateBack: @escaping () -> Void,
        onOpenURL: @escaping (URL) -> Void,
        onContinueWithGoogle: @escaping () -> Void,
        onContinueWithApple: @escaping () -> Void
    ) {
        let vm = viewModel ?? SignUpViewModel()
        _viewModel = StateObject(wrappedValue: vm)
        self.onNavigateBack = onNavigateBack
        self.onOpenURL = onOpenURL
        self.onContinueWithGoogle = onContinueWithGoogle
        self.onContinueWithApple = onContinueWithApple
    }

    public var body: some View {
        SignUpScreen(state: viewModel.state, onEvent: viewModel.send)
            .task {
                for await effect in viewModel.effects {
                    switch effect {
                    case .navigateBack:
                        onNavigateBack()
                    case .openURL(let url):
                        onOpenURL(url)
                    case .continueWithGoogle:
                        onContinueWithGoogle()
                    case .continueWithApple:
                        onContinueWithApple()
                    case .showToast:
                        break
                    }
                }
            }
    }
}

