import Foundation

// MARK: - SetPrintOrderUiEffect

public enum SetPrintOrderUiEffect: Equatable {

    /// Dismiss the full-screen and return to Home.
    case navigateBack

    /// Show a brief toast message (save confirmation, error, etc.).
    case showToast(String)
}
