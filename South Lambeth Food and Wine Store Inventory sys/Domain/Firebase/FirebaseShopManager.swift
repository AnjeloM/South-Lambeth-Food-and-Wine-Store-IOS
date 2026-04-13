import FirebaseAuth
import FirebaseFirestore
import Foundation

// MARK: - ShopManaging

public protocol ShopManaging {
    /// Fetches the signed-in user's shops from Firestore and their role.
    /// Throws `ShopManagerError.unauthenticated` if no user is signed in.
    func loadShops() async throws -> (entries: [SwitchShopEntry], isOwner: Bool)

    /// Owner only — creates a new shop document and updates the owner's shopIDs.
    func addShop(name: String, address: String, phone: String) async throws -> SwitchShopEntry

    /// Owner only — updates name, address and phone on an existing shop document.
    func updateShop(id: String, name: String, address: String, phone: String) async throws

    /// Owner only — deletes the shop document and removes it from the owner's shopIDs.
    func removeShop(id: String) async throws

    /// Owner only — marks one shop as the global default for all users, clearing any previous default.
    /// Writes `isDefault: true` to the target shop and `isDefault: false` to all other owner shops.
    func setDefaultShop(id: String) async throws

    /// Persists the current working shop ID to both Firestore (`users/{uid}.currentShopID`) and
    /// the local UserDefaults cache. Used when a user or owner switches their active shop.
    func setCurrentShop(id: String) async throws

    /// Persists the active shop ID to UserDefaults (synchronous, local only).
    func setActiveShop(id: String)

    /// Reads the persisted active shop ID from UserDefaults.
    func activeShopId() -> String?

    /// Owner only — fetches all employees for a given shop, including their names and roles.
    func loadEmployees(for shopId: String) async throws -> [ShopEmployee]
}

// MARK: - ShopManagerError

public enum ShopManagerError: Error, LocalizedError {
    case unauthenticated
    case userDocumentMissing
    case shopDocumentMissing(id: String)

    public var errorDescription: String? {
        switch self {
        case .unauthenticated:       return "You must be signed in to manage shops."
        case .userDocumentMissing:   return "Your account could not be found. Please sign in again."
        case .shopDocumentMissing(let id): return "Shop \(id) could not be found."
        }
    }
}

// MARK: - FirebaseShopManager

/// Production implementation — queries Firestore directly using the signed-in user's UID.
public struct FirebaseShopManager: ShopManaging {

    private let db = Firestore.firestore()
    private let activeShopKey = "app.activeShopId"

    public init() {}

    // MARK: Load

    public func loadShops() async throws -> (entries: [SwitchShopEntry], isOwner: Bool) {
        guard let uid = Auth.auth().currentUser?.uid else {
            throw ShopManagerError.unauthenticated
        }

        // Fetch user document to determine role
        let userDoc = try await db.collection("users").document(uid).getDocument()
        guard userDoc.exists, let userData = userDoc.data() else {
            throw ShopManagerError.userDocumentMissing
        }

        let role = userData["role"] as? String ?? "standard"
        let isOwner = (role == "owner")

        // Prefer Firestore's persisted currentShopID; fall back to local UserDefaults cache
        let firestoreActiveId = userData["currentShopID"] as? String
        let savedActiveId = firestoreActiveId ?? activeShopId()
        var entries: [SwitchShopEntry] = []

        if isOwner {
            // Fetch all shops owned by this user
            let snapshot = try await db.collection("shops")
                .whereField("ownerUserID", isEqualTo: uid)
                .getDocuments()

            entries = snapshot.documents.compactMap { doc in
                shopEntry(from: doc.data(), docId: doc.documentID)
            }
        } else {
            // Fetch shops by the IDs stored on the user document
            let shopIDs = userData["shopIDs"] as? [String] ?? []
            for shopId in shopIDs {
                let shopDoc = try await db.collection("shops").document(shopId).getDocument()
                guard shopDoc.exists, let data = shopDoc.data() else { continue }
                if let entry = shopEntry(from: data, docId: shopDoc.documentID) {
                    entries.append(entry)
                }
            }
        }

        // Mark the active shop: stored ID takes priority, fallback to first
        entries = markActiveShop(entries, activeId: savedActiveId)
        return (entries, isOwner)
    }

    // MARK: Add

    public func addShop(name: String, address: String, phone: String) async throws -> SwitchShopEntry {
        guard let uid = Auth.auth().currentUser?.uid else {
            throw ShopManagerError.unauthenticated
        }

        let shopId = UUID().uuidString
        let now = Timestamp(date: Date())

        let batch = db.batch()

        // shops/{shopId}
        let shopRef = db.collection("shops").document(shopId)
        batch.setData([
            "shopID":      shopId,
            "name":        name,
            "address":     address,
            "ownerUserID": uid,
            "phone":       phone,
            "isDefault":   false,
            "latitude":    NSNull(),
            "longitude":   NSNull(),
            "createdAt":   now,
            "updatedAt":   now,
        ], forDocument: shopRef)

        // users/{uid}.shopIDs — append the new shopId
        let userRef = db.collection("users").document(uid)
        batch.updateData(["shopIDs": FieldValue.arrayUnion([shopId])], forDocument: userRef)

        // employees/{uid}_{shopId}
        let empId = "\(uid)_\(shopId)"
        let empRef = db.collection("employees").document(empId)
        batch.setData([
            "employeeID": empId,
            "userID":     uid,
            "shopID":     shopId,
            "role":       "owner",
            "createdAt":  now,
            "updatedAt":  now,
        ], forDocument: empRef)

        try await batch.commit()

        return SwitchShopEntry(id: shopId, name: name, address: address, phone: phone)
    }

    // MARK: Update

    public func updateShop(id: String, name: String, address: String, phone: String) async throws {
        guard Auth.auth().currentUser != nil else {
            throw ShopManagerError.unauthenticated
        }

        let now = Timestamp(date: Date())
        try await db.collection("shops").document(id).updateData([
            "name":      name,
            "address":   address,
            "phone":     phone,
            "updatedAt": now,
        ])
    }

    // MARK: Remove

    public func removeShop(id: String) async throws {
        guard let uid = Auth.auth().currentUser?.uid else {
            throw ShopManagerError.unauthenticated
        }

        let batch = db.batch()

        // Delete shops/{id}
        batch.deleteDocument(db.collection("shops").document(id))

        // Remove from users/{uid}.shopIDs; also clear currentShopID if it was this shop
        var userUpdate: [String: Any] = ["shopIDs": FieldValue.arrayRemove([id])]
        if activeShopId() == id {
            userUpdate["currentShopID"] = FieldValue.delete()
        }
        batch.updateData(userUpdate, forDocument: db.collection("users").document(uid))

        // Delete employees/{uid}_{id}
        batch.deleteDocument(db.collection("employees").document("\(uid)_\(id)"))

        try await batch.commit()

        // Clear active shop if it was the removed one
        if activeShopId() == id {
            UserDefaults.standard.removeObject(forKey: activeShopKey)
        }
    }

    // MARK: Set Default Shop

    public func setDefaultShop(id: String) async throws {
        guard let uid = Auth.auth().currentUser?.uid else {
            throw ShopManagerError.unauthenticated
        }

        // Fetch all shops owned by this user so we can clear any existing default
        let snapshot = try await db.collection("shops")
            .whereField("ownerUserID", isEqualTo: uid)
            .getDocuments()

        let batch = db.batch()
        for doc in snapshot.documents {
            batch.updateData(
                ["isDefault": doc.documentID == id],
                forDocument: doc.reference
            )
        }
        try await batch.commit()
    }

    // MARK: Set Current Shop

    public func setCurrentShop(id: String) async throws {
        guard let uid = Auth.auth().currentUser?.uid else {
            throw ShopManagerError.unauthenticated
        }
        try await db.collection("users").document(uid).updateData([
            "currentShopID": id
        ])
        setActiveShop(id: id)  // keep local cache in sync for offline reads
    }

    // MARK: Load Employees

    public func loadEmployees(for shopId: String) async throws -> [ShopEmployee] {
        // Query employees collection for this shop
        let snapshot = try await db.collection("employees")
            .whereField("shopID", isEqualTo: shopId)
            .getDocuments()

        // Fetch user names in parallel
        return try await withThrowingTaskGroup(of: ShopEmployee?.self) { group in
            for doc in snapshot.documents {
                let data = doc.data()
                guard let userID = data["userID"] as? String,
                      let role   = data["role"]   as? String else { continue }

                group.addTask {
                    let userDoc = try? await self.db.collection("users").document(userID).getDocument()
                    let name = userDoc?.data()?["name"] as? String ?? "Unknown"
                    return ShopEmployee(id: userID, name: name, roleLabel: Self.roleLabel(for: role))
                }
            }

            var employees: [ShopEmployee] = []
            for try await employee in group {
                if let e = employee { employees.append(e) }
            }
            // Sort: owner first, then alphabetically by name
            return employees.sorted {
                if $0.roleLabel == "Owner" && $1.roleLabel != "Owner" { return true }
                if $0.roleLabel != "Owner" && $1.roleLabel == "Owner" { return false }
                return $0.name < $1.name
            }
        }
    }

    private static func roleLabel(for role: String) -> String {
        switch role {
        case "owner":      return "Owner"
        case "supervisor": return "Supervisor"
        case "admin":      return "Admin"
        default:           return "Employee"
        }
    }

    // MARK: Active Shop

    public func setActiveShop(id: String) {
        UserDefaults.standard.set(id, forKey: activeShopKey)
    }

    public func activeShopId() -> String? {
        UserDefaults.standard.string(forKey: activeShopKey)
    }

    // MARK: - Helpers

    private func shopEntry(from data: [String: Any], docId: String) -> SwitchShopEntry? {
        guard let name    = data["name"]    as? String,
              let address = data["address"] as? String
        else { return nil }
        let phone      = data["phone"]      as? String ?? ""
        let isDefault  = data["isDefault"]  as? Bool   ?? false
        return SwitchShopEntry(id: docId, name: name, address: address, phone: phone, isDefaultShop: isDefault)
    }

    private func markActiveShop(_ entries: [SwitchShopEntry], activeId: String?) -> [SwitchShopEntry] {
        guard !entries.isEmpty else { return entries }

        // Priority 1: stored currentShopID (Firestore or UserDefaults) matches a known shop
        if let activeId, entries.contains(where: { $0.id == activeId }) {
            return entries.map { e in
                var copy = e
                copy.isCurrentShop = (e.id == activeId)
                return copy
            }
        }

        // Priority 2: shop marked as global default by the owner
        if let defaultShop = entries.first(where: { $0.isDefaultShop }) {
            setActiveShop(id: defaultShop.id)
            return entries.map { e in
                var copy = e
                copy.isCurrentShop = (e.id == defaultShop.id)
                return copy
            }
        }

        // Priority 3: first available shop
        var result = entries
        result[0].isCurrentShop = true
        for i in 1..<result.count { result[i].isCurrentShop = false }
        setActiveShop(id: result[0].id)
        return result
    }
}

// MARK: - DemoShopManager

/// Stub for previews and unit tests — returns mock data after a short delay.
public struct DemoShopManager: ShopManaging {

    private let activeShopKey = "app.activeShopId"
    public var ownerMode: Bool

    public init(ownerMode: Bool = true) {
        self.ownerMode = ownerMode
    }

    public func loadShops() async throws -> (entries: [SwitchShopEntry], isOwner: Bool) {
        try await Task.sleep(nanoseconds: 600_000_000)
        let activeId = activeShopId() ?? SwitchShopUiState.mockShops.first?.id
        let entries = SwitchShopUiState.mockShops.map { e -> SwitchShopEntry in
            var copy = e
            copy.isCurrentShop = (e.id == activeId)
            return copy
        }
        return (entries, ownerMode)
    }

    public func addShop(name: String, address: String, phone: String) async throws -> SwitchShopEntry {
        try await Task.sleep(nanoseconds: 400_000_000)
        return SwitchShopEntry(name: name, address: address, phone: phone)
    }

    public func updateShop(id: String, name: String, address: String, phone: String) async throws {
        try await Task.sleep(nanoseconds: 400_000_000)
    }

    public func removeShop(id: String) async throws {
        try await Task.sleep(nanoseconds: 400_000_000)
        if activeShopId() == id {
            UserDefaults.standard.removeObject(forKey: activeShopKey)
        }
    }

    public func setDefaultShop(id: String) async throws {
        try await Task.sleep(nanoseconds: 300_000_000)
    }

    public func setCurrentShop(id: String) async throws {
        try await Task.sleep(nanoseconds: 200_000_000)
        setActiveShop(id: id)
    }

    public func setActiveShop(id: String) {
        UserDefaults.standard.set(id, forKey: activeShopKey)
    }

    public func activeShopId() -> String? {
        UserDefaults.standard.string(forKey: activeShopKey)
    }

    public func loadEmployees(for shopId: String) async throws -> [ShopEmployee] {
        try await Task.sleep(nanoseconds: 400_000_000)
        return ShopEmployee.mockEmployees(for: shopId)
    }
}
