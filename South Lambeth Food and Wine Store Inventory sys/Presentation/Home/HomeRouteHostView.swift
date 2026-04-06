import SwiftUI

public struct HomeRouteHostView: View {
    @StateObject private var viewModel = HomeViewModel()
    @State private var showScanner = false

    private let onNavigateWelcome: () -> Void

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
                }
            }
            .fullScreenCover(isPresented: $showScanner) {
                ScannerRouteHostView(onClose: { showScanner = false })
            }
    }
}
