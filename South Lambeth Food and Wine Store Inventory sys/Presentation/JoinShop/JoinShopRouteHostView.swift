import SwiftUI

// MARK: - JoinShopRouteHostView

@MainActor
public struct JoinShopRouteHostView: View {

    @StateObject private var viewModel: JoinShopViewModel

    private let onNavigateWelcome: () -> Void

    public init(
        sessionManager: SessionManaging = LocalSessionManager(),
        onNavigateWelcome: @escaping () -> Void
    ) {
        _viewModel = StateObject(
            wrappedValue: JoinShopViewModel(sessionManager: sessionManager)
        )
        self.onNavigateWelcome = onNavigateWelcome
    }

    public var body: some View {
        JoinShopScreen(state: viewModel.state, onEvent: viewModel.onEvent)
            .onChange(of: viewModel.effect) { _, newEffect in
                guard let newEffect else { return }
                switch newEffect {
                case .navigateWelcome:
                    onNavigateWelcome()
                case .showToast:
                    break // Toast handled in-screen via AppRootView if needed
                }
            }
    }
}
