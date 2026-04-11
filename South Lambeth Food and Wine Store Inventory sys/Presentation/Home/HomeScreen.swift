import SwiftUI

public struct HomeScreen: View {
    public let state: HomeState
    public let onEvent: (HomeEvent) -> Void

    public init(state: HomeState, onEvent: @escaping (HomeEvent) -> Void) {
        self.state = state
        self.onEvent = onEvent
    }

    @State private var isDrawerOpen = false

    // Binding bridge — keeps AppBottomNavBar in sync without a separate @State
    private var tabBinding: Binding<AppNavTab> {
        Binding(
            get: { state.selectedTab },
            set: { onEvent(.tabChanged($0)) }
        )
    }

    public var body: some View {
        ZStack(alignment: .leading) {

            // MARK: Main content
            VStack(spacing: 0) {
                tabContent
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                AppBottomNavBar(
                    selectedTab: tabBinding,
                    onScanTapped: { onEvent(.scanTapped) }
                )
                .padding(.bottom, 12)
            }
            .navigationBarBackButtonHidden(true)

            // MARK: Drawer overlay
            AppDrawer(
                isOpen: $isDrawerOpen,
                onLogout: { onEvent(.onSignOutTapped) },
                onSetPrintOrderTapped: { onEvent(.openSetPrintOrder) },
                onManageShopTapped: { onEvent(.openManageShop) },
                defaultPrintList: state.defaultPrintList
            )
        }
    }

    // MARK: - Tab Content Switch

    @ViewBuilder
    private var tabContent: some View {
        switch state.selectedTab {
        case .home:
            HomeDashboardView(onDrawerTapped: { isDrawerOpen = true })
        case .inventory:
            InventoryRouteHostView(onDrawerTapped: { isDrawerOpen = true })
        case .report:
            ReportScreen(onDrawerTapped: { isDrawerOpen = true })
        case .categories:
            CategoriesScreen(onDrawerTapped: { isDrawerOpen = true })
        }
    }
}

// MARK: - Home Dashboard (the .home tab content)

private struct HomeDashboardView: View {
    let onDrawerTapped: () -> Void

    @Environment(\.colorScheme) private var scheme
    @State private var searchText = ""

    var body: some View {
        VStack(spacing: 0) {
            // MARK: Header
            AppScreenHeader(title: "Home", onDrawerTapped: onDrawerTapped)

            // MARK: Search & Filter
            AppSearchFilterBar(text: $searchText)
                .padding(.top, 12)
                .padding(.bottom, 8)

            // MARK: Dashboard content
            ScrollView {
                VStack(spacing: 14) {
                    Spacer().frame(height: 20)

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
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, AppTheme.Layout.screenHPadding)
                .padding(.bottom, 20)
            }
        }
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
