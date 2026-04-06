import SwiftUI

@MainActor
public struct SendResetMailRouteHostView: View {
    @StateObject private var viewModel: SendResetMailViewModel

    private let onNavigateBack: () -> Void
    private let onShowToast: (String) -> Void

    public init(
        viewModel: SendResetMailViewModel? = nil,
        onNavigateBack: @escaping () -> Void,
        onShowToast: @escaping (String) -> Void
    ) {
        let vm = viewModel ?? SendResetMailViewModel()
        _viewModel = StateObject(wrappedValue: vm)
        self.onNavigateBack = onNavigateBack
        self.onShowToast = onShowToast
    }

    public var body: some View {
        SendResetMailScreen(
            state: viewModel.state,
            onEvent: viewModel.send
        )
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
