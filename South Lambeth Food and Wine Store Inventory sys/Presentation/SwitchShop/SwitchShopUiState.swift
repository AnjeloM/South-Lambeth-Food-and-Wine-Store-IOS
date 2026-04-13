import Foundation

// MARK: - ShopEmployee

public struct ShopEmployee: Identifiable, Equatable {
    public var id: String           // userID
    public var name: String
    public var roleLabel: String

    public init(id: String, name: String, roleLabel: String) {
        self.id = id
        self.name = name
        self.roleLabel = roleLabel
    }

    // MARK: - Mock data (previews / DemoShopManager only)

    public static func mockEmployees(for shopId: String) -> [ShopEmployee] {
        switch shopId {
        case "mock-shop-1":
            return [
                ShopEmployee(id: "u1", name: "Alice Owner",  roleLabel: "Owner"),
                ShopEmployee(id: "u2", name: "Bob Williams", roleLabel: "Supervisor"),
                ShopEmployee(id: "u3", name: "Carol Jones",  roleLabel: "Employee"),
            ]
        case "mock-shop-2":
            return [
                ShopEmployee(id: "u1", name: "Alice Owner",  roleLabel: "Owner"),
                ShopEmployee(id: "u4", name: "Dan Brown",    roleLabel: "Employee"),
            ]
        default:
            return [
                ShopEmployee(id: "u1", name: "Alice Owner", roleLabel: "Owner"),
            ]
        }
    }
}

// MARK: - SwitchShopEntry

public struct SwitchShopEntry: Identifiable, Equatable {
    /// Firestore document ID (UUID string from the `shops` collection).
    public var id: String
    public var name: String
    public var address: String
    public var phone: String
    public var isCurrentShop: Bool
    /// True when this shop is the global default for all users — persisted as `isDefault` in Firestore.
    public var isDefaultShop: Bool

    public init(
        id: String = UUID().uuidString,
        name: String,
        address: String,
        phone: String = "",
        isCurrentShop: Bool = false,
        isDefaultShop: Bool = false
    ) {
        self.id = id
        self.name = name
        self.address = address
        self.phone = phone
        self.isCurrentShop = isCurrentShop
        self.isDefaultShop = isDefaultShop
    }
}

// MARK: - SwitchShopUiState

public struct SwitchShopUiState: Equatable {

    // MARK: Shops
    public var shops: [SwitchShopEntry] = []

    // MARK: Loading
    /// True while the initial Firestore fetch is in flight.
    public var isLoadingShops: Bool = false

    // MARK: Role — owner sees add/edit/remove; user sees switch with confirm
    public var isOwner: Bool = false

    // MARK: Switching (user & owner)
    public var isSwitching: Bool = false
    public var toastMessage: String? = nil

    // MARK: User — switch confirmation
    /// Non-nil while the "Switch to X?" alert is presented.
    public var pendingSwitchShopId: String? = nil

    // MARK: Owner — add / edit shop form
    public var isShopFormPresented: Bool = false
    /// nil = add mode, non-nil = edit mode.
    public var editingShopId: String? = nil
    public var draftName: String = ""
    public var draftAddress: String = ""
    public var draftPhone: String = ""

    // MARK: Owner — delete confirm sheet
    public var deletingShopId: String? = nil
    public var deleteConfirmText: String = ""
    public var isDeletingShop: Bool = false

    // MARK: Owner — set default shop
    /// True while the Firestore batch to change the default shop is in flight.
    public var isSettingDefault: Bool = false

    // MARK: Owner — employee list per shop (lazy loaded on expand)
    public var expandedShopIds: Set<String> = []
    public var employeesByShop: [String: [ShopEmployee]] = [:]
    public var loadingEmployeesForShop: Set<String> = []

    // MARK: Owner — signup requests
    public var employeeRequests: [EmployeeSignupRequest] = []
    public var isLoadingRequests: Bool = false
    public var isRequestsExpanded: Bool = false
    public var highlightedRequestId: String? = nil
    public var selectedRequestId: String? = nil
    public var isUpdatingRequest: Bool = false

    public init() {}

    // MARK: - Derived

    public var currentShop: SwitchShopEntry? {
        shops.first(where: { $0.isCurrentShop })
    }

    public var otherShops: [SwitchShopEntry] {
        shops.filter { !$0.isCurrentShop }
    }

    public var shopBeingDeleted: SwitchShopEntry? {
        guard let id = deletingShopId else { return nil }
        return shops.first(where: { $0.id == id })
    }

    public var pendingSwitchShop: SwitchShopEntry? {
        guard let id = pendingSwitchShopId else { return nil }
        return shops.first(where: { $0.id == id })
    }

    public var isDeleteConfirmValid: Bool { deleteConfirmText == "CONFIRM" }

    public var isFormValid: Bool {
        !draftName.trimmingCharacters(in: .whitespaces).isEmpty &&
        !draftAddress.trimmingCharacters(in: .whitespaces).isEmpty
    }

    public var selectedRequest: EmployeeSignupRequest? {
        guard let id = selectedRequestId else { return nil }
        return employeeRequests.first(where: { $0.id == id })
    }

    // MARK: - Mock data (previews / DemoShopManager only)

    public static let mockShops: [SwitchShopEntry] = [
        SwitchShopEntry(id: "mock-shop-1", name: "South Lambeth Store",   address: "12 South Lambeth Rd, London SW8 1RT", phone: "020 7820 1234", isCurrentShop: true,  isDefaultShop: true),
        SwitchShopEntry(id: "mock-shop-2", name: "Stockwell Off Licence", address: "45 Stockwell Rd, London SW9 9BT",     phone: "020 7820 5678", isCurrentShop: false, isDefaultShop: false),
        SwitchShopEntry(id: "mock-shop-3", name: "Brixton Road Store",    address: "89 Brixton Rd, London SW9 8PA",       phone: "",              isCurrentShop: false, isDefaultShop: false),
    ]
}
