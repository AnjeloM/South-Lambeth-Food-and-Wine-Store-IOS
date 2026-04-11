import Foundation

// MARK: - OwnerShopEntry
//
// A single shop belonging to the owner.
// latitude/longitude are reserved for future Google Maps picker integration.

public struct OwnerShopEntry: Identifiable, Equatable, Hashable {
    public var id: UUID
    public var name: String
    public var address: String
    /// Masked display string — stored as formatted text (e.g. "07700 900123").
    public var phone: String
    /// Human-readable location label from the Google Maps picker.
    /// MARK: Firebase – pending (Google Maps picker will populate this + lat/lng)
    public var locationLabel: String
    public var latitude: Double?    // MARK: Firebase – pending
    public var longitude: Double?   // MARK: Firebase – pending

    public init(
        id: UUID = UUID(),
        name: String = "",
        address: String = "",
        phone: String = "",
        locationLabel: String = "",
        latitude: Double? = nil,
        longitude: Double? = nil
    ) {
        self.id = id
        self.name = name
        self.address = address
        self.phone = phone
        self.locationLabel = locationLabel
        self.latitude = latitude
        self.longitude = longitude
    }
}

// MARK: - OwnerSignUpUiState

public struct OwnerSignUpUiState: Equatable {

    // MARK: Account details
    public var name: String = ""
    public var email: String = ""
    public var password: String = ""
    public var retypePassword: String = ""
    public var isPasswordVisible: Bool = false
    public var isRetypePasswordVisible: Bool = false

    // MARK: Field errors
    public var nameError: String? = nil
    public var emailError: String? = nil

    // MARK: Shops list
    public var shops: [OwnerShopEntry] = []
    /// The shop the owner has designated as their primary / default location.
    public var defaultShopId: UUID? = nil

    // MARK: Shop add/edit sheet
    public var isShopSheetPresented: Bool = false
    /// nil → adding a new shop; non-nil → editing the shop with this id
    public var editingShopId: UUID? = nil
    public var draftShop: OwnerShopEntry = OwnerShopEntry()
    public var draftShopNameError: String? = nil
    public var draftShopAddressError: String? = nil

    // MARK: Delete confirmation sheet
    public var isDeleteConfirmPresented: Bool = false
    public var shopPendingDeleteId: UUID? = nil
    public var deleteConfirmText: String = ""

    // MARK: Submit
    public var isLoading: Bool = false

    // MARK: - Derived

    /// True only when the user has typed the magic word.
    public var isDeleteConfirmValid: Bool { deleteConfirmText == "CONFIRM" }

    /// Convenience accessor for the currently selected default shop.
    public var defaultShop: OwnerShopEntry? {
        guard let id = defaultShopId else { return nil }
        return shops.first(where: { $0.id == id })
    }

    /// Title shown in the shop sheet header.
    public var shopSheetTitle: String { editingShopId == nil ? "Add Shop" : "Edit Shop" }

    /// Password rules shown below the password field.
    public var passwordRules: [String] = [
        "At least 8 characters",
        "Must contain at least 2 lowercase and 2 uppercase letters",
        "Must contain at least 1 number",
        "Must contain at least 1 special character (e.g. !, @, #, ?)"
    ]

    public init() {}
}
