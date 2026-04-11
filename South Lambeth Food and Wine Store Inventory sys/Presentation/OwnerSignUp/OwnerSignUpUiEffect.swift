import Foundation

// MARK: - OwnerSignUpUiEffect

public enum OwnerSignUpUiEffect {
    case navigateBack
    case showToast(String)
    /// OTP was sent — navigate to the verification screen carrying the in-memory credentials
    /// and the shop list so `AppRootView` can call `registerOwner` after verification.
    case navigateToOtp(
        email: String,
        name: String,
        password: String,
        shops: [OwnerShopEntry],
        defaultShopId: UUID
    )
}
