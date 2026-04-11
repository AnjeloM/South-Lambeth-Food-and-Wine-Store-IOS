//
//  SignUpDependencies.swift
//  South Lambeth Food and Wine Store Inventory sys
//

import FirebaseFunctions
import FirebaseFirestore

// MARK: - SignUpOtpSending

public protocol SignUpOtpSending {
    /// Triggers the `sendEmailOtp` Cloud Function, which sends a 4-digit OTP
    /// to the given address via AWS SES. Throws on network or server error.
    func sendOtp(to email: String) async throws
}

// MARK: - FirebaseSignUpOtpSender

/// Production implementation — calls the `sendEmailOtp` Firebase callable function.
public struct FirebaseSignUpOtpSender: SignUpOtpSending {
    public init() {}

    public func sendOtp(to email: String) async throws {
        let functions = Functions.functions(region: "europe-north1")
        let callable = functions.httpsCallable("sendEmailOtp")
        _ = try await callable.call(["email": email, "ttlSeconds": 300])
    }
}

// MARK: - DemoSignUpOtpSender

/// Stub for previews and unit tests — simulates 500 ms latency, always succeeds.
public struct DemoSignUpOtpSender: SignUpOtpSending {
    public init() {}

    public func sendOtp(to email: String) async throws {
        try await Task.sleep(nanoseconds: 500_000_000)
    }
}

// MARK: - OwnerFetching

public protocol OwnerFetching {
    /// Fetches all registered owners (role == "owner") and their shops from Firestore.
    func fetchOwners() async throws -> [SignUpOwner]
}

// MARK: - FirebaseOwnerFetcher

/// Production implementation — queries the `users` and `shops` Firestore collections.
public struct FirebaseOwnerFetcher: OwnerFetching {
    public init() {}

    public func fetchOwners() async throws -> [SignUpOwner] {
        let db = Firestore.firestore()

        let usersSnapshot = try await db.collection("users")
            .whereField("role", isEqualTo: "owner")
            .getDocuments()

        var owners: [SignUpOwner] = []

        for userDoc in usersSnapshot.documents {
            let data = userDoc.data()
            guard let name = data["name"] as? String else { continue }

            let shopsSnapshot = try await db.collection("shops")
                .whereField("ownerUserID", isEqualTo: userDoc.documentID)
                .getDocuments()

            let shops: [SignUpShop] = shopsSnapshot.documents.compactMap { shopDoc in
                let sd = shopDoc.data()
                guard
                    let shopName    = sd["name"]    as? String,
                    let shopAddress = sd["address"] as? String
                else { return nil }
                return SignUpShop(id: shopDoc.documentID, name: shopName, address: shopAddress)
            }

            let storeName = shops.first?.name ?? ""
            owners.append(SignUpOwner(
                id: userDoc.documentID,
                name: name,
                storeName: storeName,
                shops: shops
            ))
        }

        return owners
    }
}

// MARK: - DemoOwnerFetcher

/// Stub for previews and unit tests — returns mock owners after a short delay.
public struct DemoOwnerFetcher: OwnerFetching {
    public init() {}

    public func fetchOwners() async throws -> [SignUpOwner] {
        try await Task.sleep(nanoseconds: 600_000_000)
        return SignUpUiState.mockOwners
    }
}
