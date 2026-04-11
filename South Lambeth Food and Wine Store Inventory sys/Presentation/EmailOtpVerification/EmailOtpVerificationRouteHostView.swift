import SwiftUI

@MainActor
public struct EmailOtpVerificationRouteHostView: View {
    @StateObject private var viewModel: EmailOtpVerificationViewModel

    public let onBack: () -> Void
    public let onVerified: () -> Void
    public let onToast: (String) -> Void
    private let onLoadingChanged: (Bool) -> Void

    public init(
        email: String,
        service: EmailOtpServicing,
        onBack: @escaping () -> Void,
        onVerified: @escaping () -> Void,
        onToast: @escaping (String) -> Void,
        onLoadingChanged: @escaping (Bool) -> Void = { _ in }
    ) {
        self._viewModel = StateObject(
            wrappedValue: EmailOtpVerificationViewModel(email: email, service: service)
        )
        self.onBack = onBack
        self.onVerified = onVerified
        self.onToast = onToast
        self.onLoadingChanged = onLoadingChanged
    }

    public var body: some View {
        EmailOtpVerificationScreen(
            state: viewModel.state,
            onEvent: viewModel.send
        )
        .onChange(of: viewModel.state.isVerifying) { _, newValue in
            onLoadingChanged(newValue)
        }
        .task {
            for await effect in viewModel.effects {
                switch effect {
                case .navigateBack:
                    onBack()
                case .verifiedSuccessfully:
                    onVerified()
                case let .showToast(message):
                    onToast(message)
                }
            }
        }
    }
}
