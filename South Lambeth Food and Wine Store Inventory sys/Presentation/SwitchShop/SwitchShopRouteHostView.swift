import SwiftUI

// MARK: - SwitchShopRouteHostView

/// Owns the ViewModel, wires Effects to navigation closures, and passes
/// state + onEvent down to SwitchShopScreen.
public struct SwitchShopRouteHostView: View {

    @StateObject private var viewModel: SwitchShopViewModel

    private let onClose: () -> Void

    // MARK: - Init

    /// - Parameter shopManager: Injected shop data source.
    ///   Use `FirebaseShopManager()` in production and `DemoShopManager()` for previews.
    public init(
        shopManager: ShopManaging = DemoShopManager(),
        requestManager: EmployeeRequestManaging = DemoEmployeeRequestCenter(),
        initialHighlightedRequestID: String? = nil,
        onClose: @escaping () -> Void
    ) {
        _viewModel = StateObject(
            wrappedValue: SwitchShopViewModel(
                shopManager: shopManager,
                requestManager: requestManager,
                initialHighlightedRequestID: initialHighlightedRequestID
            )
        )
        self.onClose = onClose
    }

    // MARK: - Body

    public var body: some View {
        SwitchShopScreen(
            state: viewModel.state,
            onEvent: viewModel.onEvent
        )
        .onChange(of: viewModel.effect) { _, effect in
            guard let effect else { return }
            switch effect {
            case .close:
                onClose()
            case .showToast:
                break // handled inside SwitchShopScreen's toast overlay
            }
        }
    }
}
