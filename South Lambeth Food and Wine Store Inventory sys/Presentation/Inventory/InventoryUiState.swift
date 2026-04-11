import Foundation

// MARK: - InventoryFilter

public enum InventoryFilter: Equatable {
    case totalItems   // show all
    case lowStock
    case outOfStock
}

// MARK: - InventoryItem

public struct InventoryItem: Identifiable, Equatable {
    public let id: UUID
    public let name: String
    public let category: String
    public let sku: String
    public let stock: Int
    public let icon: String

    public var isLowStock: Bool   { stock > 0 && stock < 10 }
    public var isOutOfStock: Bool { stock == 0 }

    public init(
        id: UUID = UUID(),
        name: String,
        category: String,
        sku: String,
        stock: Int,
        icon: String
    ) {
        self.id       = id
        self.name     = name
        self.category = category
        self.sku      = sku
        self.stock    = stock
        self.icon     = icon
    }
}

// MARK: - InventoryUiState

public struct InventoryUiState: Equatable {

    // MARK: Week context
    public var selectedWeek: Int    // 1 – 52
    public var selectedMonth: Int   // 1 – 12
    public var selectedYear: Int

    // MARK: Inventory presence (mock)
    public var inventoryExistsForSelectedWeek: Bool

    // MARK: Active filter (single-select)
    public var activeFilter: InventoryFilter

    // MARK: Search
    public var searchText: String

    // MARK: Items (mock)
    public var allItems: [InventoryItem]

    // MARK: - Derived — filtered items

    public var filteredItems: [InventoryItem] {
        let searched: [InventoryItem] = searchText.isEmpty
            ? allItems
            : allItems.filter {
                $0.name.localizedCaseInsensitiveContains(searchText)
                    || $0.category.localizedCaseInsensitiveContains(searchText)
                    || $0.sku.localizedCaseInsensitiveContains(searchText)
            }
        switch activeFilter {
        case .totalItems: return searched
        case .lowStock:   return searched.filter { $0.isLowStock }
        case .outOfStock: return searched.filter { $0.isOutOfStock }
        }
    }

    // MARK: - Derived — stat counts

    public var totalItemCount: Int   { allItems.count }
    public var lowStockCount: Int    { allItems.filter { $0.isLowStock }.count }
    public var outOfStockCount: Int  { allItems.filter { $0.isOutOfStock }.count }

    // MARK: - Derived — display strings

    private static let monthNames: [String] = Calendar.current.monthSymbols

    public var monthName: String {
        guard (1...12).contains(selectedMonth) else { return "" }
        return Self.monthNames[selectedMonth - 1]
    }

    /// e.g. "Week 15 • April 2026"
    public var weekHeaderLabel: String {
        "Week \(selectedWeek) • \(monthName) \(selectedYear)"
    }

    // MARK: - Init

    public init(
        selectedWeek: Int                  = Calendar.current.component(.weekOfYear, from: Date()),
        selectedMonth: Int                 = Calendar.current.component(.month,      from: Date()),
        selectedYear: Int                  = Calendar.current.component(.year,       from: Date()),
        inventoryExistsForSelectedWeek: Bool = true,
        activeFilter: InventoryFilter      = .totalItems,
        searchText: String                 = "",
        allItems: [InventoryItem]          = InventoryUiState.mockItems
    ) {
        self.selectedWeek                  = selectedWeek
        self.selectedMonth                 = selectedMonth
        self.selectedYear                  = selectedYear
        self.inventoryExistsForSelectedWeek = inventoryExistsForSelectedWeek
        self.activeFilter                  = activeFilter
        self.searchText                    = searchText
        self.allItems                      = allItems
    }

    // MARK: - Mock data

    /// Weeks that are considered to already have inventory data (demo only).
    public static let weeksWithInventory: Set<Int> = [13, 14, 15]

    public static let mockItems: [InventoryItem] = [
        InventoryItem(name: "Merlot Red Wine",         category: "Wine",        sku: "WN-001", stock: 48,  icon: "wineglass.fill"),
        InventoryItem(name: "Heineken 330ml",           category: "Beer",        sku: "BR-012", stock: 120, icon: "mug.fill"),
        InventoryItem(name: "Grey Goose Vodka 70cl",    category: "Spirits",     sku: "SP-034", stock: 7,   icon: "drop.fill"),
        InventoryItem(name: "Coca-Cola 2L",             category: "Soft Drinks", sku: "SD-007", stock: 60,  icon: "cup.and.saucer.fill"),
        InventoryItem(name: "Prosecco Brut 75cl",       category: "Wine",        sku: "WN-022", stock: 3,   icon: "wineglass"),
        InventoryItem(name: "Walkers Crisps (Box)",     category: "Snacks",      sku: "SN-005", stock: 24,  icon: "basket.fill"),
        InventoryItem(name: "San Pellegrino 750ml",     category: "Soft Drinks", sku: "SD-019", stock: 0,   icon: "drop.circle.fill"),
        InventoryItem(name: "Jack Daniel's 70cl",       category: "Spirits",     sku: "SP-011", stock: 0,   icon: "drop.fill"),
        InventoryItem(name: "Corona Extra 330ml",       category: "Beer",        sku: "BR-033", stock: 5,   icon: "mug.fill"),
        InventoryItem(name: "Pringles Original (Box)",  category: "Snacks",      sku: "SN-022", stock: 18,  icon: "basket.fill"),
    ]
}
