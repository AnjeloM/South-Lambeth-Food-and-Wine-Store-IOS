import Foundation

// MARK: - SwitchShopUiEffect

public enum SwitchShopUiEffect: Equatable {

    /// Dismiss the screen.
    case close

    /// Show a toast banner.
    case showToast(String)
}
