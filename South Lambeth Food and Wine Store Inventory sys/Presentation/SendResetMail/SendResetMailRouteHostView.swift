import SwiftUI

@MainActor
public struct SendResetMailRouteHostView: View {
    @StateObject private var viewModel: SendResetMailViewModel

    private let onNavigateBack: () -> Void
    private let onShowToast: (String) -> Void
    private let onLoadingChanged: (Bool) -> Void

    public init(
        sender: PasswordResetSending = DemoPasswordResetSender(),
        onNavigateBack: @escaping () -> Void,
        onShowToast: @escaping (String) -> Void,
        onLoadingChanged: @escaping (Bool) -> Void = { _ in }
    ) {
        _viewModel = StateObject(wrappedValue: SendResetMailViewModel(sender: sender))
        self.onNavigateBack = onNavigateBack
        self.onShowToast = onShowToast
        self.onLoadingChanged = onLoadingChanged
    }

    public var body: some View {
        SendResetMailScreen(
            state: viewModel.state,
            onEvent: viewModel.send
        )
        .onChange(of: viewModel.state.isSubmitting) { _, newValue in
            onLoadingChanged(newValue)
        }
        .task {
            // Collect one-off effects
            for await effect in viewModel.effect {
                switch effect {
                case .navigateBack:
                    onNavigateBack()

                case .showToast(let message):
                    onShowToast(message)
                }
            }
        }
    }
}
