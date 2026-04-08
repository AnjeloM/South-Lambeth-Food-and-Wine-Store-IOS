import SwiftUI

// MARK: - Tab Definition

public enum AppNavTab: CaseIterable, Hashable {
    case home
    case inventory
    case report
    case categories

    public var label: String {
        switch self {
        case .home:       return "Home"
        case .inventory:  return "Inventory"
        case .report:     return "Report"
        case .categories: return "Cat"
        }
    }

    public var icon: String {
        switch self {
        case .home:       return "house.fill"
        case .inventory:  return "storefront"
        case .report:     return "calendar"
        case .categories: return "square.grid.2x2"
        }
    }
}

// MARK: - Bottom Nav Bar

/// Reusable bottom navigation bar with an elevated centre scan button.
///
/// Usage:
/// ```swift
/// AppBottomNavBar(
///     selectedTab: $selectedTab,
///     onScanTapped: { /* open scanner */ }
/// )
/// ```
public struct AppBottomNavBar: View {

    @Binding public var selectedTab: AppNavTab
    public let onScanTapped: () -> Void

    public init(selectedTab: Binding<AppNavTab>, onScanTapped: @escaping () -> Void) {
        self._selectedTab = selectedTab
        self.onScanTapped = onScanTapped
    }

    // MARK: Constants

    private let barHeight: CGFloat = 70
    private let scanButtonSize: CGFloat = 60
    private let scanButtonLift: CGFloat = 22

    @Environment(\.colorScheme) private var scheme

    // Left tabs | right tabs split
    private let leftTabs:  [AppNavTab] = [.home, .inventory]
    private let rightTabs: [AppNavTab] = [.report, .categories]

    public var body: some View {
        ZStack(alignment: .top) {

            // MARK: Bar — frosted glass blur
            HStack(spacing: 0) {
                ForEach(leftTabs, id: \.self) { tab in tabButton(tab) }

                Spacer().frame(width: scanButtonSize + 24)

                ForEach(rightTabs, id: \.self) { tab in tabButton(tab) }
            }
            .frame(height: barHeight)
            .padding(.horizontal, 8)
            .background(
                RoundedRectangle(cornerRadius: barHeight / 2, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: barHeight / 2, style: .continuous)
                            .strokeBorder(
                                AppTheme.Colors.fieldBorderVariant(scheme).opacity(0.5),
                                lineWidth: AppTheme.Layout.fieldBorderWidth
                            )
                    )
            )
            .padding(.top, scanButtonLift)

            // MARK: Elevated scan button
            Button(action: onScanTapped) {
                ZStack {
                    Circle()
                        .fill(AppTheme.Colors.accent(scheme))
                        .frame(width: scanButtonSize, height: scanButtonSize)
                        .shadow(
                            color: AppTheme.Colors.accent(scheme).opacity(0.35),
                            radius: 8, x: 0, y: 4
                        )

                    Image(systemName: "barcode.viewfinder")
                        .font(.system(size: 26, weight: .medium))
                        .foregroundStyle(AppTheme.Colors.buttonText(scheme))
                }
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Tab Button

    @ViewBuilder
    private func tabButton(_ tab: AppNavTab) -> some View {
        let isActive = selectedTab == tab

        Button {
            selectedTab = tab
        } label: {
            VStack(spacing: 4) {
                Image(systemName: tab.icon)
                    .font(.system(size: 20, weight: isActive ? .semibold : .regular))

                Text(tab.label)
                    .font(AppTheme.Typography.caption)
            }
            .foregroundStyle(
                isActive
                    ? AppTheme.Colors.accent(scheme)
                    : AppTheme.Colors.secondaryText(scheme)
            )
            .frame(maxWidth: .infinity)
            .frame(height: barHeight)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.18), value: selectedTab)
    }
}

// MARK: - Previews

#Preview("NavBar - Light") {
    struct Wrapper: View {
        @State private var tab: AppNavTab = .home
        var body: some View {
            VStack {
                Spacer()
                AppBottomNavBar(selectedTab: $tab, onScanTapped: {})
            }
            .background(Color(.systemBackground))
        }
    }
    return Wrapper().preferredColorScheme(.light)
}

#Preview("NavBar - Dark") {
    struct Wrapper: View {
        @State private var tab: AppNavTab = .home
        var body: some View {
            VStack {
                Spacer()
                AppBottomNavBar(selectedTab: $tab, onScanTapped: {})
            }
            .background(Color(hex: 0x1C1C1E))
        }
    }
    return Wrapper().preferredColorScheme(.dark)
}
