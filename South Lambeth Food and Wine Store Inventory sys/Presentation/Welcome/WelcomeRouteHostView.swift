import SwiftUI
import Combine

public enum WelcomeRoute: Equatable {
    case signIn
}

public struct WelcomeRouteHostView: View {
    @StateObject private var viewModel: WelcomeViewModel

    private let onNavigate: (WelcomeRoute) -> Void

    public init(onNavigate: @escaping (WelcomeRoute) -> Void) {
        _viewModel = StateObject(wrappedValue: WelcomeViewModel())
        self.onNavigate = onNavigate
    }

    public var body: some View {
        WelcomeScreen(
            state: viewModel.state,
            onEvent: viewModel.onEvent
        )
        .onReceive(viewModel.effects) { effect in
            switch effect {
            case .navigateToSignIn:
                onNavigate(.signIn)
            }
        }
    }
}

#Preview("WelcomeRouteHostView - Light") {
    WelcomeRouteHostView(onNavigate: { _ in })
        .preferredColorScheme(.light)
}

#Preview("WelcomeRouteHostView - Dark") {
    WelcomeRouteHostView(onNavigate: { _ in })
        .preferredColorScheme(.dark)
}
