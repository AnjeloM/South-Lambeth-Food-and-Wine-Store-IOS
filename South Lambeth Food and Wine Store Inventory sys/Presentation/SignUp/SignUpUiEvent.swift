import Foundation

public enum SignUpUiEvent: Equatable {
    case onAppear
    case onbackTapped

    // Input cases
    case nameChanged(String)
    case emailChanged(String)
    case passwordChanged(String)
    case retypePasswordChanged(String)

    // Toggles
    case togglePasswordVisibility
    case toggleRetypePasswordVisibility

    // Social actions
    case googleTapped
    case appleTapped

    // Footer links
    case privacyPolicyTapped
    case termsTapped

    // Primary action
    case signUpTapped

    // MARK: Store Assignment
    case ownerPickerTapped
    case shopPickerTapped
    case ownerSelected(SignUpOwner)
    case shopSelected(SignUpShop)
    case clearOwnerSelection
    case ownerPickerDismissed
    case shopPickerDismissed
}
