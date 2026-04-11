import SwiftUI
import Combine

// MARK: - InventoryRouteHostView
//
// Owns the InventoryViewModel, bridges state/events to InventoryScreen,
// and forwards drawer-open intent (pure UI concern) from the host.

@MainActor
public struct InventoryRouteHostView: View {

    @State private var viewModel = InventoryViewModel()

    public let onDrawerTapped: () -> Void

    public init(onDrawerTapped: @escaping () -> Void = {}) {
        self.onDrawerTapped = onDrawerTapped
    }

    public var body: some View {
        InventoryScreen(
            state:         viewModel.state,
            onEvent:       viewModel.onEvent,
            onDrawerTapped: onDrawerTapped
        )
    }
}

