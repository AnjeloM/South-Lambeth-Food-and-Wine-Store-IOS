import Foundation

// MARK: - RoleSelectionUiState

public struct RoleSelectionUiState: Equatable {

    public var title: String = "Create Account"

    // MARK: User role card
    public var userRoleTitle: String       = "Sign Up as User"
    public var userRoleDescription: String = "Access inventory, view reports, and manage daily stock."
    public var userRoleIcon: String        = "person.fill"

    // MARK: Owner role card
    public var ownerRoleTitle: String       = "Sign Up as Owner"
    public var ownerRoleDescription: String = "Register your store(s), manage your team, and oversee multiple locations."
    public var ownerRoleIcon: String        = "building.2.fill"

    public init() {}
}
