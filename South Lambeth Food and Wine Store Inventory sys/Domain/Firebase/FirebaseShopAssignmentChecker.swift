import FirebaseAuth
import FirebaseFirestore
import Foundation

// MARK: - ShopAssignmentChecking

public protocol ShopAssignmentChecking {
    /// Returns true if the signed-in user has at least one shop in `users/{uid}.shopIDs`.
    func hasShopAssignment() async -> Bool
}

// MARK: - ShopRequestSubmitting

public protocol ShopRequestSubmitting {
    /// Writes a `pendingRequests` document for the signed-in user requesting to join a shop.
    func submitJoinRequest(shopID: String) async throws
    /// Returns a pending request for the signed-in user, if one exists.
    func pendingRequest() async throws -> PendingShopRequest?
}

// MARK: - PendingShopRequest

public struct PendingShopRequest: Equatable {
    public var requestID: String
    public var shopID: String
    public var shopName: String?

    public init(requestID: String, shopID: String, shopName: String? = nil) {
        self.requestID = requestID
        self.shopID = shopID
        self.shopName = shopName
    }
}

// MARK: - FirebaseShopAssignmentChecker

public struct FirebaseShopAssignmentChecker: ShopAssignmentChecking {

    private let db = Firestore.firestore()

    public init() {}

    public func hasShopAssignment() async -> Bool {
        guard let uid = Auth.auth().currentUser?.uid else { return false }
        guard let data = try? await db.collection("users").document(uid).getDocument().data() else {
            return false
        }
        let shopIDs = data["shopIDs"] as? [String] ?? []
        return !shopIDs.isEmpty
    }
}

// MARK: - FirebaseShopRequestSubmitter

public struct FirebaseShopRequestSubmitter: ShopRequestSubmitting {

    private let db = Firestore.firestore()

    public init() {}

    public func submitJoinRequest(shopID: String) async throws {
        guard let user = Auth.auth().currentUser else {
            throw ShopRequestError.unauthenticated
        }

        // Read name + email from the Firestore user doc (more reliable than Auth post-registration)
        let userDoc = try await db.collection("users").document(user.uid).getDocument()
        let userData = userDoc.data() ?? [:]
        let name  = userData["name"]  as? String ?? user.displayName ?? "Unknown"
        let email = userData["email"] as? String ?? user.email ?? ""

        let requestID = UUID().uuidString
        let notificationID = UUID().uuidString
        let now = Timestamp(date: Date())
        let shopDoc = try await db.collection("shops").document(shopID).getDocument()
        let shopData = shopDoc.data() ?? [:]
        let shopName = shopData["name"] as? String ?? "your shop"
        let ownerUserID = shopData["ownerUserID"] as? String ?? ""

        let batch = db.batch()

        batch.setData([
            "requestID":   requestID,
            "userID":      user.uid,
            "name":        name,
            "email":       email,
            "shopID":      shopID,
            "status":      "pending",
            "requestedAt": now,
            "approvedBy":  NSNull(),
            "approvedAt":  NSNull(),
        ], forDocument: db.collection("pendingRequests").document(requestID))

        if !ownerUserID.isEmpty {
            batch.setData([
                "notificationID": notificationID,
                "userID": ownerUserID,
                "shopID": shopID,
                "title": "New employee signup request",
                "message": "\(name) requested access to \(shopName).",
                "type": "employee_signup_request",
                "referenceID": requestID,
                "metadata": [
                    "requestID": requestID,
                    "shopID": shopID,
                    "employeeUserID": user.uid,
                ],
                "isRead": false,
                "createdAt": now,
                "readAt": NSNull(),
                "createdBy": user.uid,
            ], forDocument: db.collection("notifications").document(notificationID))
        }

        try await batch.commit()
    }

    public func pendingRequest() async throws -> PendingShopRequest? {
        guard let uid = Auth.auth().currentUser?.uid else { return nil }

        let snapshot = try await db.collection("pendingRequests")
            .whereField("userID", isEqualTo: uid)
            .whereField("status", isEqualTo: "pending")
            .limit(to: 1)
            .getDocuments()

        guard let doc = snapshot.documents.first else { return nil }
        let data = doc.data()
        let shopID = data["shopID"] as? String ?? ""

        // Resolve shop name for display
        var shopName: String? = nil
        if let shopDoc = try? await db.collection("shops").document(shopID).getDocument(),
           let sName = shopDoc.data()?["name"] as? String {
            shopName = sName
        }

        return PendingShopRequest(requestID: doc.documentID, shopID: shopID, shopName: shopName)
    }
}

// MARK: - Errors

public enum ShopRequestError: Error {
    case unauthenticated
}

// MARK: - Demo Stubs

public struct DemoShopAssignmentChecker: ShopAssignmentChecking {
    public let hasShops: Bool
    public init(hasShops: Bool = false) { self.hasShops = hasShops }
    public func hasShopAssignment() async -> Bool { hasShops }
}

public struct DemoShopRequestSubmitter: ShopRequestSubmitting {
    public let existingRequest: PendingShopRequest?
    public init(existingRequest: PendingShopRequest? = nil) {
        self.existingRequest = existingRequest
    }
    public func submitJoinRequest(shopID: String) async throws {
        try await Task.sleep(nanoseconds: 700_000_000)
    }
    public func pendingRequest() async throws -> PendingShopRequest? {
        try await Task.sleep(nanoseconds: 300_000_000)
        return existingRequest
    }
}
