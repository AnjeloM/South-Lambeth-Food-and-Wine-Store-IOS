import SwiftUI

public struct ScannerRouteHostView: View {

    @StateObject private var viewModel = ScannerViewModel()

    private let onClose: () -> Void

    public init(onClose: @escaping () -> Void) {
        self.onClose = onClose
    }

    public var body: some View {
        ScannerScreen(state: viewModel.state, onEvent: viewModel.send)
            .task {
                for await effect in viewModel.effects {
                    handle(effect)
                }
            }
    }

    private func handle(_ effect: ScannerUiEffect) {
        switch effect {
        case .close:
            onClose()
        case .triggerHaptic:
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
    }
}

#Preview("Scanner") {
    ScannerRouteHostView(onClose: {})
}
