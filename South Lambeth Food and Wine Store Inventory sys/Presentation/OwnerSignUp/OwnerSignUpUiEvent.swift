import Foundation

// MARK: - OwnerSignUpUiEvent

public enum OwnerSignUpUiEvent {

    // MARK: Navigation
    case backTapped

    // MARK: Account details
    case nameChanged(String)
    case emailChanged(String)
    case passwordChanged(String)
    case retypePasswordChanged(String)
    case togglePasswordVisible
    case toggleRetypePasswordVisible

    // MARK: Shop list actions
    case addShopTapped
    case editShopTapped(id: UUID)
    case deleteShopTapped(id: UUID)
    case defaultShopSelected(id: UUID)

    // MARK: Shop add/edit sheet
    case draftShopNameChanged(String)
    case draftShopAddressChanged(String)
    case draftShopPhoneChanged(String)
    /// Placeholder — will open Google Maps picker once integrated.
    case draftShopLocationTapped
    case saveShopTapped
    case cancelShopSheetTapped

    // MARK: Delete confirmation sheet
    case deleteConfirmTextChanged(String)
    case confirmDeleteTapped
    case cancelDeleteTapped

    // MARK: Submit
    case signUpTapped
}
