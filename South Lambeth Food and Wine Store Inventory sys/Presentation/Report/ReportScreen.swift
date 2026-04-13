import SwiftUI

public struct ReportScreen: View {

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

    @Environment(\.colorScheme) private var scheme
    @State private var searchText = ""

    public var body: some View {
        VStack(spacing: 0) {
            // MARK: Header
            AppScreenHeader(
                title: "Reports",
                hasUnreadNotification: hasUnreadNotification,
                onNotificationTapped: onNotificationTapped,
                onDrawerTapped: onDrawerTapped
            )

            // MARK: Search & Filter
            AppSearchFilterBar(text: $searchText)
                .padding(.top, 12)
                .padding(.bottom, 8)

            ScrollView {
                VStack(spacing: 16) {

                    // Period picker placeholder
                    HStack {
                        Text("Period")
                            .font(AppTheme.Typography.caption)
                            .foregroundStyle(AppTheme.Colors.secondaryText(scheme))
                        Spacer()
                        periodChip("Today",   isSelected: true)
                        periodChip("Week",    isSelected: false)
                        periodChip("Month",   isSelected: false)
                    }
                    .padding(.horizontal, AppTheme.Layout.screenHPadding)
                    .padding(.top, 20)

                    // KPI row
                    HStack(spacing: 12) {
                        kpiCard(value: "£ 4,820", label: "Revenue",      icon: "sterlingsign.circle.fill")
                        kpiCard(value: "136",     label: "Sales",         icon: "cart.fill")
                        kpiCard(value: "£ 35.44", label: "Avg. Basket",  icon: "chart.bar.fill")
                    }
                    .padding(.horizontal, AppTheme.Layout.screenHPadding)

                    // Top sellers
                    sectionHeader("Top Sellers")

                    VStack(spacing: 0) {
                        ForEach(Array(topSellers.enumerated()), id: \.offset) { index, item in
                            topSellerRow(rank: index + 1, item: item)
                            if index < topSellers.count - 1 {
                                Divider().padding(.leading, AppTheme.Layout.screenHPadding)
                            }
                        }
                    }
                    .background(
                        RoundedRectangle(cornerRadius: AppTheme.Layout.fieldCornerRadius, style: .continuous)
                            .fill(AppTheme.Colors.surfaceContainer(scheme))
                    )
                    .padding(.horizontal, AppTheme.Layout.screenHPadding)

                    // Stock alerts section
                    sectionHeader("Stock Alerts")

                    alertCard(
                        icon: "exclamationmark.triangle.fill",
                        title: "5 items below reorder level",
                        tint: AppTheme.Colors.error(scheme)
                    )
                    .padding(.horizontal, AppTheme.Layout.screenHPadding)

                    alertCard(
                        icon: "clock.fill",
                        title: "3 items expiring this week",
                        tint: Color.orange
                    )
                    .padding(.horizontal, AppTheme.Layout.screenHPadding)
                }
                .padding(.bottom, 20)
            }
        }
        .background(AppTheme.Colors.background(scheme).ignoresSafeArea())
    }

    // MARK: - Sub-views

    @ViewBuilder
    private func periodChip(_ label: String, isSelected: Bool) -> some View {
        Text(label)
            .font(.system(size: 13, weight: .medium))
            .foregroundStyle(isSelected ? AppTheme.Colors.buttonText(scheme) : AppTheme.Colors.primaryText(scheme))
            .padding(.horizontal, 14)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(isSelected ? AppTheme.Colors.accent(scheme) : AppTheme.Colors.surfaceContainer(scheme))
            )
    }

    @ViewBuilder
    private func kpiCard(value: String, label: String, icon: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundStyle(AppTheme.Colors.accent(scheme))
            Text(value)
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(AppTheme.Colors.primaryText(scheme))
                .minimumScaleFactor(0.7)
                .lineLimit(1)
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(AppTheme.Colors.secondaryText(scheme))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.Layout.fieldCornerRadius, style: .continuous)
                .fill(AppTheme.Colors.surfaceContainer(scheme))
        )
    }

    @ViewBuilder
    private func sectionHeader(_ title: String) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(AppTheme.Colors.primaryText(scheme))
            Spacer()
        }
        .padding(.horizontal, AppTheme.Layout.screenHPadding)
        .padding(.top, 4)
    }

    @ViewBuilder
    private func topSellerRow(rank: Int, item: (name: String, units: Int)) -> some View {
        HStack {
            Text("\(rank)")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(AppTheme.Colors.accent(scheme))
                .frame(width: 24)
            Text(item.name)
                .font(AppTheme.Typography.caption)
                .foregroundStyle(AppTheme.Colors.primaryText(scheme))
            Spacer()
            Text("\(item.units) sold")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(AppTheme.Colors.secondaryText(scheme))
        }
        .padding(.horizontal, AppTheme.Layout.screenHPadding)
        .padding(.vertical, 12)
    }

    @ViewBuilder
    private func alertCard(icon: String, title: String, tint: Color) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(tint)
            Text(title)
                .font(AppTheme.Typography.caption)
                .foregroundStyle(AppTheme.Colors.primaryText(scheme))
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 12))
                .foregroundStyle(AppTheme.Colors.secondaryText(scheme))
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.Layout.fieldCornerRadius, style: .continuous)
                .fill(AppTheme.Colors.surfaceContainer(scheme))
        )
    }

    // MARK: - Sample Data

    private let topSellers: [(name: String, units: Int)] = [
        ("Heineken 330ml",        48),
        ("Merlot Red Wine 75cl",  34),
        ("Grey Goose Vodka 70cl", 27),
        ("Coca-Cola 2L",          22),
        ("Walkers Crisps (Box)",  18),
    ]
}

// MARK: - Previews

#Preview("Report - Light") {
    ReportScreen()
        .preferredColorScheme(.light)
}

#Preview("Report - Dark") {
    ReportScreen()
        .preferredColorScheme(.dark)
}
