import SwiftUI

// MARK: - RoleSelectionRouteHostView

@MainActor
public struct RoleSelectionRouteHostView: View {

    @StateObject private var viewModel: RoleSelectionViewModel

    private let onNavigateBack: () -> Void
    private let onNavigateToUserSignUp: () -> Void
    private let onNavigateToOwnerSignUp: () -> Void

    public init(
        onNavigateBack: @escaping () -> Void,
        onNavigateToUserSignUp: @escaping () -> Void,
        onNavigateToOwnerSignUp: @escaping () -> Void
    ) {
        _viewModel = StateObject(wrappedValue: RoleSelectionViewModel())
        self.onNavigateBack = onNavigateBack
        self.onNavigateToUserSignUp = onNavigateToUserSignUp
        self.onNavigateToOwnerSignUp = onNavigateToOwnerSignUp
    }

    public var body: some View {
        RoleSelectionScreen(
            state: viewModel.state,
            onEvent: viewModel.onEvent
        )
        .task {
            for await effect in viewModel.effects {
                switch effect {
                case .navigateBack:
                    onNavigateBack()
                case .navigateToUserSignUp:
                    onNavigateToUserSignUp()
                case .navigateToOwnerSignUp:
                    onNavigateToOwnerSignUp()
                }
            }
        }
    }
}

// MARK: - Previews

#Preview("RoleSelection - Light") {
    RoleSelectionRouteHostView(
        onNavigateBack: {},
        onNavigateToUserSignUp: {},
        onNavigateToOwnerSignUp: {}
    )
    .preferredColorScheme(.light)
}

#Preview("RoleSelection - Dark") {
    RoleSelectionRouteHostView(
        onNavigateBack: {},
        onNavigateToUserSignUp: {},
        onNavigateToOwnerSignUp: {}
    )
    .preferredColorScheme(.dark)
}
