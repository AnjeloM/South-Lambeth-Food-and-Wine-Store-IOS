import SwiftUI

public struct HomeScreen: View {
    public let state: HomeState
    public let onEvent: (HomeEvent) -> Void

    public init(state: HomeState, onEvent: @escaping (HomeEvent) -> Void) {
        self.state = state
        self.onEvent = onEvent
    }

    // Binding bridge — keeps AppBottomNavBar in sync without a separate @State
    private var tabBinding: Binding<AppNavTab> {
        Binding(
            get: { state.selectedTab },
            set: { onEvent(.tabChanged($0)) }
        )
    }

    public var body: some View {
        VStack(spacing: 0) {

            // MARK: Tab Content
            tabContent
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            // MARK: Bottom Nav Bar
            AppBottomNavBar(
                selectedTab: tabBinding,
                onScanTapped: { onEvent(.scanTapped) }
            )
            .padding(.bottom, 12)
        }
        .navigationBarBackButtonHidden(true)
    }

    // MARK: - Tab Content Switch

    @ViewBuilder
    private var tabContent: some View {
        switch state.selectedTab {
        case .home:
            HomeDashboardView(
                signOutText: state.signOutButtonText,
                onSignOut: { onEvent(.onSignOutTapped) }
            )
        case .inventory:
            InventoryScreen()
        case .report:
            ReportScreen()
        case .categories:
            CategoriesScreen()
        }
    }
}

// MARK: - Home Dashboard (the .home tab content)

private struct HomeDashboardView: View {
    let signOutText: String
    let onSignOut: () -> Void

    @Environment(\.colorScheme) private var scheme

    var body: some View {
        VStack(spacing: 14) {
            Spacer()

            Image(systemName: "house.fill")
                .font(.system(size: 52))
                .foregroundStyle(AppTheme.Colors.accent(scheme))

            Text("South Lambeth")
                .font(.system(size: 26, weight: .heavy))
                .foregroundStyle(AppTheme.Colors.primaryText(scheme))

            Text("Food & Wine Store")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(AppTheme.Colors.secondaryText(scheme))

            Text("Inventory System")
                .font(AppTheme.Typography.caption)
                .foregroundStyle(AppTheme.Colors.secondaryText(scheme))
                .padding(.bottom, 20)

            Button(signOutText, action: onSignOut)
                .buttonStyle(.bordered)

            Spacer()
        }
        .padding(AppTheme.Layout.screenHPadding)
    }
}

// MARK: - Previews

#Preview("Home - Light") {
    HomeScreen(state: HomeState(), onEvent: { _ in })
        .preferredColorScheme(.light)
}

#Preview("Home - Dark") {
    HomeScreen(state: HomeState(), onEvent: { _ in })
        .preferredColorScheme(.dark)
}

#Preview("Inventory Tab") {
    HomeScreen(state: { var s = HomeState(); s.selectedTab = .inventory; return s }(),
               onEvent: { _ in })
}

#Preview("Report Tab") {
    HomeScreen(state: { var s = HomeState(); s.selectedTab = .report; return s }(),
               onEvent: { _ in })
}

#Preview("Categories Tab") {
    HomeScreen(state: { var s = HomeState(); s.selectedTab = .categories; return s }(),
               onEvent: { _ in })
}
