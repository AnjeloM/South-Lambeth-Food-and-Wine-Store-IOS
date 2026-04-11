import SwiftUI

// MARK: - OwnerSignUpRouteHostView

@MainActor
public struct OwnerSignUpRouteHostView: View {

    @StateObject private var viewModel: OwnerSignUpViewModel

    private let onNavigateBack: () -> Void
    private let onShowToast: (String) -> Void

    public init(
        onNavigateBack: @escaping () -> Void,
        onShowToast: @escaping (String) -> Void = { _ in }
    ) {
        _viewModel = StateObject(wrappedValue: OwnerSignUpViewModel())
        self.onNavigateBack = onNavigateBack
        self.onShowToast = onShowToast
    }

    public var body: some View {
        OwnerSignUpScreen(
            state: viewModel.state,
            onEvent: viewModel.onEvent
        )
        .task {
            for await effect in viewModel.effects {
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

// MARK: - Previews

#Preview("OwnerSignUp - Light") {
    OwnerSignUpRouteHostView(
        onNavigateBack: {},
        onShowToast: { _ in }
    )
    .preferredColorScheme(.light)
}

#Preview("OwnerSignUp - Dark") {
    OwnerSignUpRouteHostView(
        onNavigateBack: {},
        onShowToast: { _ in }
    )
    .preferredColorScheme(.dark)
}

#Preview("OwnerSignUp - With Shops") {
    let state: OwnerSignUpUiState = {
        var s = OwnerSignUpUiState()
        s.name  = "Nishan Perera"
        s.email = "nishan@example.com"
        s.shops = [
            OwnerShopEntry(name: "South Lambeth Store",  address: "12 South Lambeth Rd, London SW8",  phone: "02079 000123", locationLabel: "Vauxhall, London"),
            OwnerShopEntry(name: "Stockwell Off Licence", address: "45 Stockwell Rd, London SW9",      phone: "02079 004567", locationLabel: "Stockwell, London"),
        ]
        return s
    }()
    OwnerSignUpScreen(state: state, onEvent: { _ in })
        .preferredColorScheme(.light)
}
