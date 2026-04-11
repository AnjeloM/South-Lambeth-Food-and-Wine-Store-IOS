import Foundation

// MARK: - SignUpOwner
//
// Represents a registered owner visible to users during sign-up.
// MARK: Firebase – pending: replace mock data with a Firestore query
// (e.g. owners collection where isApproved == true).

public struct SignUpOwner: Identifiable, Equatable {
    public let id: UUID
    public let name: String
    public let storeName: String
    public let shops: [SignUpShop]

    public init(id: UUID = UUID(), name: String, storeName: String, shops: [SignUpShop]) {
        self.id = id
        self.name = name
        self.storeName = storeName
        self.shops = shops
    }
}

// MARK: - SignUpShop

public struct SignUpShop: Identifiable, Equatable {
    public let id: UUID
    public let name: String
    public let address: String

    public init(id: UUID = UUID(), name: String, address: String) {
        self.id = id
        self.name = name
        self.address = address
    }
}

// MARK: - SignUpUiState

public struct SignUpUiState: Equatable {
    // Title
    public var title: String = "SignUp"

    // Inputs
    public var name: String = ""
    public var email: String = ""
    public var password: String = ""
    public var retypePassword: String = ""

    // UI Toggles
    public var isPasswordVisible: Bool = false
    public var isRetypePasswordVisible: Bool = false

    // Labels
    public var nameLabel: String = "Name"
    public var emailLabel: String = "Email"
    public var passwordLabel: String = "Password"
    public var retypePasswordLabel: String = "Retype Password"

    // Password rules (static UI for now)
    public var passwordRules: [String] = [
        "At least 8 characters (required for your password)",
        "Must contain at least 2 lowercase and 2 uppercase letters.",
        "Must contain at least 1 number.",
        "Inclusion of at least one special character, e.g !, @, #, ?, )"
    ]

    // Sign Up button
    public var signUpButtonText: String = "Sign Up"
    public var isLoading: Bool = false

    // Inline error shown below the email field
    public var emailError: String? = nil

    // Social buttons
    public var googleButtonText: String = "Continue with Google"
    public var appleButtonText: String = "Continue with Apple"

    // Footer
    public var footerPrefixText: String = "By continuing forward, you agree to"
    public var footerBrandText: String = "NISHAN INVENTORY"
    public var privacyPolicyText: String = "Privacy Policy"
    public var andText: String = "and"
    public var termsText: String = "Terms & Conditions"

    // MARK: - Store Assignment
    //
    // The user must choose which owner they work for and their default shop.
    // After OTP verification the app will submit a join-request to that owner
    // for approval. MARK: Firebase – pending (join-request API call).

    /// All registered owners available for selection.
    /// MARK: Firebase – pending: replace with live Firestore query.
    public var availableOwners: [SignUpOwner] = SignUpUiState.mockOwners

    /// The owner the user has selected.
    public var selectedOwner: SignUpOwner? = nil

    /// The shop the user has selected as their default.
    public var selectedShop: SignUpShop? = nil

    /// Controls the owner-picker sheet.
    public var isOwnerPickerPresented: Bool = false

    /// Controls the shop-picker sheet (enabled only after an owner is selected).
    public var isShopPickerPresented: Bool = false

    // MARK: - Mock owners (frontend stub)
    // MARK: Firebase – pending: remove once Firestore query is wired.

    public static let mockOwners: [SignUpOwner] = [
        SignUpOwner(
            name: "Nishan Perera",
            storeName: "South Lambeth Food & Wine",
            shops: [
                SignUpShop(name: "South Lambeth Store",   address: "12 South Lambeth Rd, London SW8 1RT"),
                SignUpShop(name: "Stockwell Off Licence",  address: "45 Stockwell Rd, London SW9 9BT"),
            ]
        ),
        SignUpOwner(
            name: "James Okafor",
            storeName: "Brixton Convenience",
            shops: [
                SignUpShop(name: "Brixton Main Store", address: "78 Coldharbour Ln, London SE5 9NR"),
            ]
        ),
        SignUpOwner(
            name: "Aisha Rahman",
            storeName: "Clapham Express",
            shops: [
                SignUpShop(name: "Clapham North Branch", address: "3 Clapham High St, London SW4 7TS"),
                SignUpShop(name: "Clapham South Branch", address: "102 Clapham Park Rd, London SW4 7BZ"),
            ]
        ),
    ]

    public init() {}
}
