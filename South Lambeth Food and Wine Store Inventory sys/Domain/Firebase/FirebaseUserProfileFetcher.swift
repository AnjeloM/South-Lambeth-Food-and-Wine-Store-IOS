import FirebaseAuth
import FirebaseFirestore
import Foundation

// MARK: - DrawerProfile

public struct DrawerProfile: Equatable {
    public var name: String
    public var roleLabel: String
    public var shopName: String

    public init(name: String, roleLabel: String, shopName: String) {
        self.name = name
        self.roleLabel = roleLabel
        self.shopName = shopName
    }
}

// MARK: - Protocol

public protocol UserProfileFetching {
    func fetchProfile() async throws -> DrawerProfile
}

// MARK: - Firebase Implementation

public struct FirebaseUserProfileFetcher: UserProfileFetching {

    private let db = Firestore.firestore()
    private let activeShopKey = "app.activeShopId"

    public init() {}

    public func fetchProfile() async throws -> DrawerProfile {
        guard let user = Auth.auth().currentUser else {
            throw ProfileFetchError.unauthenticated
        }

        let userDoc = try await db.collection("users").document(user.uid).getDocument()
        guard let data = userDoc.data() else {
            throw ProfileFetchError.userDocumentMissing
        }

        let name = data["name"] as? String
            ?? user.displayName
            ?? user.email
            ?? "User"

        let role = data["role"] as? String ?? "standard"
        let roleLabel = Self.roleLabel(for: role)

        // Prefer Firestore's currentShopID, fall back to local UserDefaults cache
        let shopID = data["currentShopID"] as? String
            ?? UserDefaults.standard.string(forKey: activeShopKey)

        var shopName = "No Shop Assigned"
        if let shopID {
            if let shopDoc = try? await db.collection("shops").document(shopID).getDocument(),
               let shopData = shopDoc.data(),
               let sName = shopData["name"] as? String {
                shopName = sName
            }
        }

        return DrawerProfile(name: name, roleLabel: roleLabel, shopName: shopName)
    }

    // MARK: - Helpers

    private static func roleLabel(for role: String) -> String {
        switch role {
        case "owner":      return "Owner"
        case "supervisor": return "Supervisor"
        case "admin":      return "Admin"
        default:           return "Employee"
        }
    }
}

// MARK: - Errors

public enum ProfileFetchError: Error {
    case unauthenticated
    case userDocumentMissing
}

// MARK: - Demo Stub

public struct DemoUserProfileFetcher: UserProfileFetching {
    public let profile: DrawerProfile

    public init(
        name: String = "Jane Smith",
        roleLabel: String = "Supervisor",
        shopName: String = "South Lambeth Store"
    ) {
        self.profile = DrawerProfile(name: name, roleLabel: roleLabel, shopName: shopName)
    }

    public func fetchProfile() async throws -> DrawerProfile { profile }
}
