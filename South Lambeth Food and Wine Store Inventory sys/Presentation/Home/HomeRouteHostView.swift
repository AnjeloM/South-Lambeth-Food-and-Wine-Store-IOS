import SwiftUI

public struct HomeRouteHostView: View {
    @StateObject private var viewModel = HomeViewModel()
    @State private var showScanner = false
    @State private var showSetPrintOrder = false
    @State private var showManageShop = false

    private let onNavigateWelcome: () -> Void

    // MARK: Firebase – pending: inject PrintOrderRepositoring here when Firebase is wired.
    private let printOrderRepository: PrintOrderRepositoring = LocalPrintOrderRepository()

    public init(onNavigateWelcome: @escaping () -> Void) {
        self.onNavigateWelcome = onNavigateWelcome
    }

    public var body: some View {
        HomeScreen(state: viewModel.state, onEvent: viewModel.onEvent)
            .onChange(of: viewModel.effect) { _, newEffect in
                guard let newEffect else { return }
                switch newEffect {
                case .navigateWelcome:
                    onNavigateWelcome()
                case .openScanner:
                    showScanner = true
                case .openSetPrintOrder:
                    showSetPrintOrder = true
                case .openManageShop:
                    showManageShop = true
                }
            }
            .fullScreenCover(isPresented: $showScanner) {
                ScannerRouteHostView(onClose: { showScanner = false })
            }
            .fullScreenCover(isPresented: $showSetPrintOrder) {
                SetPrintOrderRouteHostView(
                    repository: printOrderRepository,
                    onClose: {
                        showSetPrintOrder = false
                        viewModel.onEvent(.onSetPrintOrderClosed)
                    }
                )
            }
            .fullScreenCover(isPresented: $showManageShop) {
                SwitchShopRouteHostView(
                    shopManager: FirebaseShopManager(),
                    onClose: { showManageShop = false }
                )
            }
    }
}
