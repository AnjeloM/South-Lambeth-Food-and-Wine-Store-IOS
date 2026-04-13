import FirebaseAuth
import FirebaseFirestore
import Foundation

// MARK: - OwnerRequestNotification

public struct OwnerRequestNotification: Identifiable, Equatable {
    public var id: String
    public var requestID: String
    public var shopID: String
    public var title: String
    public var message: String

    public init(id: String, requestID: String, shopID: String, title: String, message: String) {
        self.id = id
        self.requestID = requestID
        self.shopID = shopID
        self.title = title
        self.message = message
    }
}

// MARK: - EmployeeSignupRequest

public struct EmployeeSignupRequest: Identifiable, Equatable {
    public var id: String
    public var userID: String
    public var shopID: String
    public var shopName: String
    public var employeeName: String
    public var employeeEmail: String
    public var employeeProfileImageURL: String?
    public var status: String
    public var requestedAt: Date

    public init(
        id: String,
        userID: String,
        shopID: String,
        shopName: String,
        employeeName: String,
        employeeEmail: String,
        employeeProfileImageURL: String? = nil,
        status: String,
        requestedAt: Date
    ) {
        self.id = id
        self.userID = userID
        self.shopID = shopID
        self.shopName = shopName
        self.employeeName = employeeName
        self.employeeEmail = employeeEmail
        self.employeeProfileImageURL = employeeProfileImageURL
        self.status = status
        self.requestedAt = requestedAt
    }
}

// MARK: - Protocols

public protocol OwnerNotificationReading {
    func latestUnreadRequestNotification() async throws -> OwnerRequestNotification?
    func markNotificationRead(id: String) async throws
}

public protocol EmployeeRequestManaging {
    func loadPendingRequests() async throws -> [EmployeeSignupRequest]
    func approveRequest(id: String) async throws
    func rejectRequest(id: String) async throws
}

// MARK: - FirebaseEmployeeRequestCenter

public struct FirebaseEmployeeRequestCenter: OwnerNotificationReading, EmployeeRequestManaging {
    private let db = Firestore.firestore()

    public init() {}

    public func latestUnreadRequestNotification() async throws -> OwnerRequestNotification? {
        guard let uid = Auth.auth().currentUser?.uid else { return nil }

        let snapshot = try await db.collection("notifications")
            .whereField("userID", isEqualTo: uid)
            .whereField("isRead", isEqualTo: false)
            .getDocuments()

        let notification = snapshot.documents.compactMap { doc -> (OwnerRequestNotification, Date)? in
            let data = doc.data()
            let metadata = data["metadata"] as? [String: Any]
            let shopID = (data["shopID"] as? String) ?? (metadata?["shopID"] as? String)
            guard
                let type = data["type"] as? String,
                type == "employee_signup_request",
                let requestID = data["referenceID"] as? String,
                let shopID,
                let title = data["title"] as? String,
                let message = data["message"] as? String
            else { return nil }

            let createdAt = (data["createdAt"] as? Timestamp)?.dateValue() ?? .distantPast
            return (
                OwnerRequestNotification(
                    id: doc.documentID,
                    requestID: requestID,
                    shopID: shopID,
                    title: title,
                    message: message
                ),
                createdAt
            )
        }
        .sorted { $0.1 > $1.1 }
        .first

        return notification?.0
    }

    public func markNotificationRead(id: String) async throws {
        let now = Timestamp(date: Date())
        try await db.collection("notifications").document(id).updateData([
            "isRead": true,
            "readAt": now,
        ])
    }

    public func loadPendingRequests() async throws -> [EmployeeSignupRequest] {
        guard let uid = Auth.auth().currentUser?.uid else { return [] }

        let shopsSnapshot = try await db.collection("shops")
            .whereField("ownerUserID", isEqualTo: uid)
            .getDocuments()

        let ownedShops = shopsSnapshot.documents.map { ($0.documentID, $0.data()["name"] as? String ?? "Shop") }
        guard !ownedShops.isEmpty else { return [] }

        return try await withThrowingTaskGroup(of: [EmployeeSignupRequest].self) { group in
            for (shopID, shopName) in ownedShops {
                group.addTask {
                    let requestSnapshot = try await db.collection("pendingRequests")
                        .whereField("shopID", isEqualTo: shopID)
                        .whereField("status", isEqualTo: "pending")
                        .getDocuments()

                    return requestSnapshot.documents.map { doc in
                        let data = doc.data()
                        return EmployeeSignupRequest(
                            id: doc.documentID,
                            userID: data["userID"] as? String ?? "",
                            shopID: shopID,
                            shopName: shopName,
                            employeeName: data["name"] as? String ?? "Unknown",
                            employeeEmail: data["email"] as? String ?? "",
                            employeeProfileImageURL: data["profileImageURL"] as? String,
                            status: data["status"] as? String ?? "pending",
                            requestedAt: (data["requestedAt"] as? Timestamp)?.dateValue() ?? .distantPast
                        )
                    }
                }
            }

            var results: [EmployeeSignupRequest] = []
            for try await chunk in group {
                results.append(contentsOf: chunk)
            }
            return results.sorted { $0.requestedAt > $1.requestedAt }
        }
    }

    public func approveRequest(id: String) async throws {
        guard let ownerID = Auth.auth().currentUser?.uid else { return }

        let requestRef = db.collection("pendingRequests").document(id)
        let requestDoc = try await requestRef.getDocument()
        guard let requestData = requestDoc.data() else { return }

        let userID = requestData["userID"] as? String ?? ""
        let shopID = requestData["shopID"] as? String ?? ""
        let shopDoc = try await db.collection("shops").document(shopID).getDocument()
        let shopName = shopDoc.data()?["name"] as? String ?? "your shop"

        let userRef = db.collection("users").document(userID)
        let userDoc = try await userRef.getDocument()
        let currentShopID = userDoc.data()?["currentShopID"] as? String
        let now = Timestamp(date: Date())

        let batch = db.batch()

        let employeeID = "\(userID)_\(shopID)"
        batch.setData([
            "employeeID": employeeID,
            "userID": userID,
            "shopID": shopID,
            "role": "standard",
            "createdAt": now,
            "updatedAt": now,
        ], forDocument: db.collection("employees").document(employeeID), merge: true)

        var userUpdate: [String: Any] = [
            "shopIDs": FieldValue.arrayUnion([shopID]),
            "updatedAt": now,
        ]
        if currentShopID == nil {
            userUpdate["currentShopID"] = shopID
        }
        batch.updateData(userUpdate, forDocument: userRef)

        batch.updateData([
            "status": "approved",
            "approvedBy": ownerID,
            "approvedAt": now,
        ], forDocument: requestRef)

        let employeeNotificationID = UUID().uuidString
        batch.setData([
            "notificationID": employeeNotificationID,
            "userID": userID,
            "shopID": shopID,
            "title": "Request Approved",
            "message": "Your request to join \(shopName) has been approved.",
            "type": "employee_request_approved",
            "referenceID": id,
            "metadata": ["requestID": id, "shopID": shopID],
            "isRead": false,
            "createdAt": now,
            "readAt": NSNull(),
            "createdBy": ownerID,
        ], forDocument: db.collection("notifications").document(employeeNotificationID))

        try await markOwnerNotificationsRead(requestID: id, ownerID: ownerID, now: now, batch: batch)
        try await batch.commit()
    }

    public func rejectRequest(id: String) async throws {
        guard let ownerID = Auth.auth().currentUser?.uid else { return }

        let requestRef = db.collection("pendingRequests").document(id)
        let requestDoc = try await requestRef.getDocument()
        guard let requestData = requestDoc.data() else { return }

        let userID = requestData["userID"] as? String ?? ""
        let shopID = requestData["shopID"] as? String ?? ""
        let shopDoc = try await db.collection("shops").document(shopID).getDocument()
        let shopName = shopDoc.data()?["name"] as? String ?? "the selected shop"
        let now = Timestamp(date: Date())

        let batch = db.batch()
        batch.updateData([
            "status": "rejected",
            "approvedBy": ownerID,
            "approvedAt": now,
        ], forDocument: requestRef)

        let employeeNotificationID = UUID().uuidString
        batch.setData([
            "notificationID": employeeNotificationID,
            "userID": userID,
            "shopID": shopID,
            "title": "Request Rejected",
            "message": "Your request to join \(shopName) was rejected. You can search again and submit a new request.",
            "type": "employee_request_rejected",
            "referenceID": id,
            "metadata": ["requestID": id, "shopID": shopID],
            "isRead": false,
            "createdAt": now,
            "readAt": NSNull(),
            "createdBy": ownerID,
        ], forDocument: db.collection("notifications").document(employeeNotificationID))

        try await markOwnerNotificationsRead(requestID: id, ownerID: ownerID, now: now, batch: batch)
        try await batch.commit()
    }

    private func markOwnerNotificationsRead(
        requestID: String,
        ownerID: String,
        now: Timestamp,
        batch: WriteBatch
    ) async throws {
        let notificationSnapshot = try await db.collection("notifications")
            .whereField("userID", isEqualTo: ownerID)
            .whereField("referenceID", isEqualTo: requestID)
            .getDocuments()

        for doc in notificationSnapshot.documents {
            batch.updateData([
                "isRead": true,
                "readAt": now,
            ], forDocument: doc.reference)
        }
    }
}

// MARK: - DemoEmployeeRequestCenter

public struct DemoEmployeeRequestCenter: OwnerNotificationReading, EmployeeRequestManaging {
    public init() {}

    public func latestUnreadRequestNotification() async throws -> OwnerRequestNotification? {
        OwnerRequestNotification(
            id: "notification-1",
            requestID: "request-1",
            shopID: "mock-shop-1",
            title: "New signup request",
            message: "Dilan Perera requested access to South Lambeth Store."
        )
    }

    public func markNotificationRead(id: String) async throws {}

    public func loadPendingRequests() async throws -> [EmployeeSignupRequest] {
        [
            EmployeeSignupRequest(
                id: "request-1",
                userID: "user-10",
                shopID: "mock-shop-1",
                shopName: "South Lambeth Store",
                employeeName: "Dilan Perera",
                employeeEmail: "dilan@example.com",
                status: "pending",
                requestedAt: Date()
            ),
            EmployeeSignupRequest(
                id: "request-2",
                userID: "user-11",
                shopID: "mock-shop-2",
                shopName: "Stockwell Off Licence",
                employeeName: "Sara Khan",
                employeeEmail: "sara@example.com",
                status: "pending",
                requestedAt: Date().addingTimeInterval(-3600)
            ),
        ]
    }

    public func approveRequest(id: String) async throws {}

    public func rejectRequest(id: String) async throws {}
}
