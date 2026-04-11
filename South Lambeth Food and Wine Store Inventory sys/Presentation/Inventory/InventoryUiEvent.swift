// MARK: - InventoryUiEvent
//
// Every user interaction or intent that can be sent into InventoryViewModel.

public enum InventoryUiEvent {

    // MARK: Search
    case searchChanged(String)

    // MARK: Week context picker
    case onSelectWeek(Int)
    case onSelectMonth(Int)
    case onSelectYear(Int)

    // MARK: Filter — single-select; one of the three stat cards
    case onTapFilter(InventoryFilter)

    // MARK: Primary action — dynamic label (Create / Edit)
    case onTapCreateOrEditInventory
}
