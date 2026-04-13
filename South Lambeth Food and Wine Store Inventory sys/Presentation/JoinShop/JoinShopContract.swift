import Foundation

// MARK: - JoinShopUiState

public struct JoinShopUiState: Equatable {

    // MARK: Search
    public var ownerSearchText: String = ""
    /// Results grouped by owner — each owner carries their matching shops.
    public var ownerSearchResults: [SignUpOwner] = []
    public var isSearchingOwners: Bool = false
    /// Shown after a successful search that returned nothing.
    public var ownerSearchIsEmpty: Bool = false

    // MARK: Confirmed selection
    public var selectedOwner: SignUpOwner? = nil
    public var selectedShop: SignUpShop? = nil

    // MARK: Picker
    public var isOwnerPickerPresented: Bool = false

    // MARK: Submission
    public var isSubmitting: Bool = false
    public var requestSent: Bool = false

    // MARK: Pre-existing pending request (detected on appear)
    public var pendingRequest: PendingShopRequest? = nil
    public var isCheckingPending: Bool = false

    public init() {}

    // MARK: - Derived

    public var isFormValid: Bool {
        selectedOwner != nil && selectedShop != nil
    }

    public var isBlocking: Bool {
        isSubmitting || isCheckingPending
    }

    /// True when the search field has enough text to trigger a query.
    public var canSearch: Bool { ownerSearchText.count >= 2 }
}

// MARK: - JoinShopUiEvent

public enum JoinShopUiEvent {
    case onAppear
    case ownerPickerTapped
    case ownerSearchChanged(String)
    case ownerPickerDismissed
    /// User taps a shop leaf in the tree — confirms selection and dismisses the sheet.
    case shopSelected(SignUpShop, owner: SignUpOwner)
    case submitTapped
    case logoutTapped
}

// MARK: - JoinShopUiEffect

public enum JoinShopUiEffect: Equatable {
    case navigateWelcome
    case showToast(String)
}
