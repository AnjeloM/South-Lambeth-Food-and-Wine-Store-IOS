import Combine
import SwiftUI

// MARK: - InventoryViewModel

@MainActor
public final class InventoryViewModel: ObservableObject {

    @Published public private(set) var state: InventoryUiState

    // MARK: - Init

    public init() {
        let calendar = Calendar.current
        let now      = Date()
        let week     = calendar.component(.weekOfYear, from: now)
        let month    = calendar.component(.month,      from: now)
        let year     = calendar.component(.year,       from: now)

        state = InventoryUiState(
            selectedWeek:                   week,
            selectedMonth:                  month,
            selectedYear:                   year,
            inventoryExistsForSelectedWeek: InventoryUiState.weeksWithInventory.contains(week)
        )
    }

    // MARK: - Event handler

    public func onEvent(_ event: InventoryUiEvent) {
        switch event {

        // MARK: Search
        case .searchChanged(let text):
            state.searchText = text

        // MARK: Week context
        case .onSelectWeek(let week):
            state.selectedWeek                   = week
            state.inventoryExistsForSelectedWeek = InventoryUiState.weeksWithInventory.contains(week)

        case .onSelectMonth(let month):
            state.selectedMonth = month

        case .onSelectYear(let year):
            state.selectedYear = year

        // MARK: Filter (single-select)
        case .onTapFilter(let filter):
            state.activeFilter = filter

        // MARK: Create / Edit inventory
        case .onTapCreateOrEditInventory:
            // MARK: Firebase – pending
            // Navigate to create-inventory or edit-inventory screen
            // once the data layer and navigation effects are wired.
            break
        }
    }
}
