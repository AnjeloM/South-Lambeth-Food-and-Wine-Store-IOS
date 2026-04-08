import SwiftUI

// MARK: - SetPrintOrderRouteHostView

/// Owns the ViewModel, wires Effects to navigation closures, and passes
/// state + onEvent down to SetPrintOrderScreen.
public struct SetPrintOrderRouteHostView: View {

    @StateObject private var viewModel: SetPrintOrderViewModel

    private let onClose: () -> Void

    // MARK: Init

    public init(repository: PrintOrderRepositoring, onClose: @escaping () -> Void) {
        self._viewModel = StateObject(
            wrappedValue: SetPrintOrderViewModel(repository: repository)
        )
        self.onClose = onClose
    }

    // MARK: Body

    public var body: some View {
        NavigationStack {
            SetPrintOrderScreen(
                state: viewModel.state,
                onEvent: viewModel.onEvent
            )
        }
        .onChange(of: viewModel.effect) { _, effect in
            guard let effect else { return }
            switch effect {
            case .navigateBack:
                onClose()
            case .showToast:
                break   // toast is rendered inside SetPrintOrderScreen's overlay
            }
        }
    }
}
