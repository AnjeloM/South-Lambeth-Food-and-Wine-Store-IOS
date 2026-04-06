import SwiftUI

public struct CategoriesScreen: View {

    public init() {}

    @Environment(\.colorScheme) private var scheme

    private let columns = [GridItem(.flexible()), GridItem(.flexible())]

    public var body: some View {
        VStack(spacing: 0) {
            AppTopBar(title: "Cat", showBack: false, showsShadow: true, onBack: {})

            ScrollView {
                LazyVGrid(columns: columns, spacing: 14) {
                    ForEach(categories) { cat in
                        categoryCard(cat)
                    }
                }
                .padding(.horizontal, AppTheme.Layout.screenHPadding)
                .padding(.top, 20)
                .padding(.bottom, 20)
            }
        }
        .background(AppTheme.Colors.background(scheme).ignoresSafeArea())
    }

    // MARK: - Category Card

    @ViewBuilder
    private func categoryCard(_ cat: ProductCategory) -> some View {
        VStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(AppTheme.Colors.primaryContainer(scheme))
                    .frame(width: 60, height: 60)
                Image(systemName: cat.icon)
                    .font(.system(size: 26))
                    .foregroundStyle(AppTheme.Colors.onPrimaryContainer(scheme))
            }

            Text(cat.name)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(AppTheme.Colors.primaryText(scheme))

            Text("\(cat.itemCount) items")
                .font(.system(size: 12))
                .foregroundStyle(AppTheme.Colors.secondaryText(scheme))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.Layout.fieldCornerRadius, style: .continuous)
                .fill(AppTheme.Colors.surfaceContainer(scheme))
        )
    }

    // MARK: - Sample Data

    private let categories: [ProductCategory] = [
        ProductCategory(name: "Wine",        icon: "wineglass.fill",        itemCount: 42),
        ProductCategory(name: "Beer",        icon: "mug.fill",              itemCount: 38),
        ProductCategory(name: "Spirits",     icon: "drop.fill",             itemCount: 55),
        ProductCategory(name: "Soft Drinks", icon: "cup.and.saucer.fill",   itemCount: 29),
        ProductCategory(name: "Snacks",      icon: "basket.fill",           itemCount: 31),
        ProductCategory(name: "Tobacco",     icon: "flame.fill",            itemCount: 18),
        ProductCategory(name: "Lottery",     icon: "ticket.fill",           itemCount: 6),
        ProductCategory(name: "Other",       icon: "ellipsis.circle.fill",  itemCount: 65),
    ]
}

private struct ProductCategory: Identifiable {
    let id = UUID()
    let name: String
    let icon: String
    let itemCount: Int
}

// MARK: - Previews

#Preview("Categories - Light") {
    CategoriesScreen()
        .preferredColorScheme(.light)
}

#Preview("Categories - Dark") {
    CategoriesScreen()
        .preferredColorScheme(.dark)
}
