import Foundation

// MARK: - SwitchShopUiEvent

public enum SwitchShopUiEvent {

    // MARK: Lifecycle
    case onAppear

    // MARK: Navigation
    case closeTapped

    // MARK: Both roles — tap on a shop row body
    case shopTapped(id: String)

    // MARK: User — switch confirmation dialog
    case switchConfirmed
    case switchCancelled

    // MARK: Owner — add / edit shop form
    case addShopTapped
    case editShopTapped(id: String)
    case draftNameChanged(String)
    case draftAddressChanged(String)
    case draftPhoneChanged(String)
    case saveShopTapped
    case shopFormDismissed

    // MARK: Owner — delete shop
    case deleteShopTapped(id: String)
    case deleteConfirmTextChanged(String)
    case confirmDeleteTapped
    case deleteSheetDismissed

    // MARK: Owner — set global default shop
    case setDefaultShopTapped(id: String)
}
