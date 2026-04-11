import SwiftUI

// MARK: - OwnerSignUpRouteHostView

@MainActor
public struct OwnerSignUpRouteHostView: View {

    @StateObject private var viewModel: OwnerSignUpViewModel

    private let onNavigateBack: () -> Void
    private let onShowToast: (String) -> Void
    private let onNavigateToOtp: (String, String, String, [OwnerShopEntry], UUID) -> Void
    private let onLoadingChanged: (Bool) -> Void

    public init(
        otpSender: SignUpOtpSending,
        onNavigateBack: @escaping () -> Void,
        onShowToast: @escaping (String) -> Void = { _ in },
        onNavigateToOtp: @escaping (String, String, String, [OwnerShopEntry], UUID) -> Void,
        onLoadingChanged: @escaping (Bool) -> Void = { _ in }
    ) {
        _viewModel = StateObject(
            wrappedValue: OwnerSignUpViewModel(otpSender: otpSender)
        )
        self.onNavigateBack    = onNavigateBack
        self.onShowToast       = onShowToast
        self.onNavigateToOtp   = onNavigateToOtp
        self.onLoadingChanged  = onLoadingChanged
    }

    public var body: some View {
        OwnerSignUpScreen(
            state: viewModel.state,
            onEvent: viewModel.onEvent
        )
        .onChange(of: viewModel.state.isLoading) { _, newValue in
            onLoadingChanged(newValue)
        }
        .task {
            for await effect in viewModel.effects {
                switch effect {
                case .navigateBack:
                    onNavigateBack()
                case .showToast(let message):
                    onShowToast(message)
                case let .navigateToOtp(email, name, password, shops, defaultShopId):
                    onNavigateToOtp(email, name, password, shops, defaultShopId)
                }
            }
        }
    }
}

// MARK: - Previews

#Preview("OwnerSignUp - Light") {
    OwnerSignUpRouteHostView(
        otpSender: DemoSignUpOtpSender(),
        onNavigateBack: {},
        onShowToast: { _ in },
        onNavigateToOtp: { _, _, _, _, _ in }
    )
    .preferredColorScheme(.light)
}

#Preview("OwnerSignUp - Dark") {
    OwnerSignUpRouteHostView(
        otpSender: DemoSignUpOtpSender(),
        onNavigateBack: {},
        onShowToast: { _ in },
        onNavigateToOtp: { _, _, _, _, _ in }
    )
    .preferredColorScheme(.dark)
}

#Preview("OwnerSignUp - With Shops") {
    let state: OwnerSignUpUiState = {
        var s = OwnerSignUpUiState()
        s.name  = "Nishan Perera"
        s.email = "nishan@example.com"
        let shop1 = OwnerShopEntry(name: "South Lambeth Store",   address: "12 South Lambeth Rd, London SW8", phone: "02079 000123", locationLabel: "Vauxhall, London")
        let shop2 = OwnerShopEntry(name: "Stockwell Off Licence", address: "45 Stockwell Rd, London SW9",     phone: "02079 004567", locationLabel: "Stockwell, London")
        s.shops = [shop1, shop2]
        s.defaultShopId = shop1.id
        return s
    }()
    OwnerSignUpScreen(state: state, onEvent: { _ in })
        .preferredColorScheme(.light)
}
