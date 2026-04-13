import SwiftUI
import Combine

// MARK: - InventoryRouteHostView
//
// Owns the InventoryViewModel, bridges state/events to InventoryScreen,
// and forwards drawer-open intent (pure UI concern) from the host.

@MainActor
public struct InventoryRouteHostView: View {

    @State private var viewModel = InventoryViewModel()

    public let hasUnreadNotification: Bool
    public let onNotificationTapped: () -> Void
    public let onDrawerTapped: () -> Void

    public init(
        hasUnreadNotification: Bool = false,
        onNotificationTapped: @escaping () -> Void = {},
        onDrawerTapped: @escaping () -> Void = {}
    ) {
        self.hasUnreadNotification = hasUnreadNotification
        self.onNotificationTapped = onNotificationTapped
        self.onDrawerTapped = onDrawerTapped
    }

    public var body: some View {
        InventoryScreen(
            state: viewModel.state,
            onEvent: viewModel.onEvent,
            hasUnreadNotification: hasUnreadNotification,
            onNotificationTapped: onNotificationTapped,
            onDrawerTapped: onDrawerTapped
        )
    }
}
