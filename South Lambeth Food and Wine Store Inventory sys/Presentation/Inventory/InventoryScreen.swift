import SwiftUI

public struct InventoryScreen: View {

    public let onDrawerTapped: () -> Void

    public init(onDrawerTapped: @escaping () -> Void = {}) {
        self.onDrawerTapped = onDrawerTapped
    }

    @Environment(\.colorScheme) private var scheme
    @State private var searchText = ""

    public var body: some View {
        VStack(spacing: 0) {
            // MARK: Header
            AppScreenHeader(title: "Inventory", onDrawerTapped: onDrawerTapped)

            // MARK: Search & Filter
            AppSearchFilterBar(text: $searchText)
                .padding(.top, 12)
                .padding(.bottom, 8)

            ScrollView {
                VStack(spacing: 20) {

                    // Summary cards
                    HStack(spacing: 12) {
                        summaryCard(value: "284", label: "Total Items",   icon: "shippingbox.fill")
                        summaryCard(value: "12",  label: "Low Stock",     icon: "exclamationmark.triangle.fill")
                        summaryCard(value: "3",   label: "Out of Stock",  icon: "xmark.circle.fill")
                    }
                    .padding(.horizontal, AppTheme.Layout.screenHPadding)
                    .padding(.top, 20)

                    // Placeholder list
                    VStack(spacing: 0) {
                        ForEach(sampleItems) { item in
                            inventoryRow(item)
                            if item.id != sampleItems.last?.id {
                                Divider()
                                    .padding(.leading, AppTheme.Layout.screenHPadding)
                            }
                        }
                    }
                    .background(
                        RoundedRectangle(cornerRadius: AppTheme.Layout.fieldCornerRadius, style: .continuous)
                            .fill(AppTheme.Colors.surfaceContainer(scheme))
                    )
                    .padding(.horizontal, AppTheme.Layout.screenHPadding)
                }
                .padding(.bottom, 20)
            }
        }
        .background(AppTheme.Colors.background(scheme).ignoresSafeArea())
    }

    // MARK: - Summary Card

    @ViewBuilder
    private func summaryCard(value: String, label: String, icon: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundStyle(AppTheme.Colors.accent(scheme))
            Text(value)
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(AppTheme.Colors.primaryText(scheme))
            Text(label)
                .font(AppTheme.Typography.caption)
                .foregroundStyle(AppTheme.Colors.secondaryText(scheme))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.Layout.fieldCornerRadius, style: .continuous)
                .fill(AppTheme.Colors.surfaceContainer(scheme))
        )
    }

    // MARK: - Inventory Row

    @ViewBuilder
    private func inventoryRow(_ item: SampleInventoryItem) -> some View {
        HStack(spacing: 14) {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(AppTheme.Colors.primaryContainer(scheme))
                .frame(width: 44, height: 44)
                .overlay {
                    Image(systemName: item.icon)
                        .foregroundStyle(AppTheme.Colors.onPrimaryContainer(scheme))
                }

            VStack(alignment: .leading, spacing: 3) {
                Text(item.name)
                    .font(AppTheme.Typography.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(AppTheme.Colors.primaryText(scheme))
                Text(item.category)
                    .font(.system(size: 12))
                    .foregroundStyle(AppTheme.Colors.secondaryText(scheme))
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 3) {
                Text("\(item.stock) units")
                    .font(AppTheme.Typography.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(item.stock < 10
                        ? AppTheme.Colors.error(scheme)
                        : AppTheme.Colors.primaryText(scheme))
                Text(item.sku)
                    .font(.system(size: 11))
                    .foregroundStyle(AppTheme.Colors.secondaryText(scheme))
            }
        }
        .padding(.horizontal, AppTheme.Layout.screenHPadding)
        .padding(.vertical, 12)
    }

    // MARK: - Sample Data

    private var sampleItems: [SampleInventoryItem] { SampleInventoryItem.samples }
}

private struct SampleInventoryItem: Identifiable {
    let id = UUID()
    let name: String
    let category: String
    let sku: String
    let stock: Int
    let icon: String

    static let samples: [SampleInventoryItem] = [
        SampleInventoryItem(name: "Merlot Red Wine",        category: "Wine",    sku: "WN-001", stock: 48,  icon: "wineglass.fill"),
        SampleInventoryItem(name: "Heineken 330ml",          category: "Beer",    sku: "BR-012", stock: 120, icon: "mug.fill"),
        SampleInventoryItem(name: "Grey Goose Vodka 70cl",   category: "Spirits", sku: "SP-034", stock: 7,   icon: "drop.fill"),
        SampleInventoryItem(name: "Coca-Cola 2L",            category: "Soft Drinks", sku: "SD-007", stock: 60, icon: "cup.and.saucer.fill"),
        SampleInventoryItem(name: "Prosecco Brut 75cl",      category: "Wine",    sku: "WN-022", stock: 3,   icon: "wineglass"),
        SampleInventoryItem(name: "Walkers Crisps (Box)",    category: "Snacks",  sku: "SN-005", stock: 24,  icon: "basket.fill"),
    ]
}

// MARK: - Previews

#Preview("Inventory - Light") {
    InventoryScreen()
        .preferredColorScheme(.light)
}

#Preview("Inventory - Dark") {
    InventoryScreen()
        .preferredColorScheme(.dark)
}
