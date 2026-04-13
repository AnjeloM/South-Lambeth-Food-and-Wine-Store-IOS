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
    /// Fetches all registered owners and their shops.
    /// Used by SignUpScreen, which loads the full list once on appear.
    func fetchOwners() async throws -> [SignUpOwner]

    /// Searches by BOTH shop name prefix AND owner name prefix.
    /// Returns owners grouped with all shops owned by each matched owner.
    /// Uses two parallel Firestore queries — no composite index required.
    func searchOwners(query: String, limit: Int) async throws -> [SignUpOwner]
}

// MARK: - FirebaseOwnerFetcher

public struct FirebaseOwnerFetcher: OwnerFetching {
    public init() {}

    // MARK: fetchOwners — parallel shop queries per owner

    public func fetchOwners() async throws -> [SignUpOwner] {
        let db = Firestore.firestore()

        let usersSnap = try await db.collection("users")
            .whereField("role", isEqualTo: "owner")
            .getDocuments()

        return try await withThrowingTaskGroup(of: SignUpOwner?.self) { group in
            for userDoc in usersSnap.documents {
                let data = userDoc.data()
                guard let name = data["name"] as? String else { continue }
                let uid = userDoc.documentID

                group.addTask {
                    let shopsSnap = try await db.collection("shops")
                        .whereField("ownerUserID", isEqualTo: uid)
                        .getDocuments()
                    let shops = Self.mapShops(shopsSnap.documents)
                    return SignUpOwner(
                        id: uid,
                        name: name,
                        storeName: shops.first?.name ?? "",
                        shops: shops
                    )
                }
            }
            var result: [SignUpOwner] = []
            for try await owner in group {
                if let o = owner { result.append(o) }
            }
            return result.sorted { $0.name < $1.name }
        }
    }

    // MARK: searchOwners — dual query: shop name prefix + owner name prefix
    //
    // Query A: shops.name prefix  → collects ownerUserID matches.
    // Query B: users.name prefix  → client-filters role=="owner".
    // Any owner matched by either query is expanded to their FULL shop list.
    // Neither query requires a composite index.

    public func searchOwners(query: String, limit: Int = 20) async throws -> [SignUpOwner] {
        let db = Firestore.firestore()
        var trimmed = query.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return [] }

        // Normalise to title-case so "south" matches "South Lambeth Store".
        trimmed = trimmed
            .split(separator: " ")
            .map { $0.prefix(1).uppercased() + $0.dropFirst() }
            .joined(separator: " ")

        let end = trimmed + "\u{f8ff}"

        // Fire both queries concurrently.
        async let shopSnapTask = db.collection("shops")
            .whereField("name", isGreaterThanOrEqualTo: trimmed)
            .whereField("name", isLessThan: end)
            .limit(to: limit)
            .getDocuments()

        async let userSnapTask = db.collection("users")
            .whereField("name", isGreaterThanOrEqualTo: trimmed)
            .whereField("name", isLessThan: end)
            .limit(to: limit)
            .getDocuments()

        let (shopSnap, userSnap) = try await (shopSnapTask, userSnapTask)

        // -- Query A: collect owner IDs from shop-name matches --
        var matchedOwnerIDs = Set<String>()
        for doc in shopSnap.documents {
            let d = doc.data()
            guard let ownerID = d["ownerUserID"] as? String else { continue }
            matchedOwnerIDs.insert(ownerID)
        }

        // -- Query B: owner-name matches (client-filter role == "owner") --
        let ownerBMatches: [(id: String, name: String)] = userSnap.documents.compactMap { doc in
            let d = doc.data()
            guard
                let name = d["name"] as? String,
                let role = d["role"] as? String, role == "owner"
            else { return nil }
            return (id: doc.documentID, name: name)
        }

        matchedOwnerIDs.formUnion(ownerBMatches.map(\.id))
        guard !matchedOwnerIDs.isEmpty else { return [] }

        let ownerShopsMap = await withTaskGroup(of: (String, [SignUpShop]).self) { group in
            for ownerID in matchedOwnerIDs {
                group.addTask {
                    let snap = try? await db.collection("shops")
                        .whereField("ownerUserID", isEqualTo: ownerID)
                        .getDocuments()
                    let shops = Self.mapShops(snap?.documents ?? []).sorted { $0.name < $1.name }
                    return (ownerID, shops)
                }
            }
            var result: [String: [SignUpShop]] = [:]
            for await (id, shops) in group { result[id] = shops }
            return result
        }

        // Build ownerID → name map. Query B already gave us names for those owners.
        var ownerNameMap: [String: String] = Dictionary(
            uniqueKeysWithValues: ownerBMatches.map { ($0.id, $0.name) }
        )

        // For Query A owners whose names we don't have yet, fetch in parallel.
        let unknownOwnerIDs = matchedOwnerIDs.filter { ownerNameMap[$0] == nil }
        if !unknownOwnerIDs.isEmpty {
            let fetched = await withTaskGroup(of: (String, String)?.self) { group in
                for ownerID in unknownOwnerIDs {
                    group.addTask {
                        guard
                            let doc  = try? await db.collection("users").document(ownerID).getDocument(),
                            let data = doc.data(),
                            let name = data["name"] as? String
                        else { return nil }
                        return (ownerID, name)
                    }
                }
                var map: [String: String] = [:]
                for await pair in group { if let p = pair { map[p.0] = p.1 } }
                return map
            }
            ownerNameMap.merge(fetched) { existing, _ in existing }
        }

        // Assemble final result.
        var result: [SignUpOwner] = []
        for (ownerID, shops) in ownerShopsMap {
            guard let ownerName = ownerNameMap[ownerID], !shops.isEmpty else { continue }
            result.append(SignUpOwner(
                id: ownerID,
                name: ownerName,
                storeName: shops.first?.name ?? "",
                shops: shops
            ))
        }
        return result
            .sorted { $0.name < $1.name }
            .prefix(limit)
            .map { $0 }
    }

    // MARK: - Helper

    private static func mapShops(_ docs: [QueryDocumentSnapshot]) -> [SignUpShop] {
        docs.compactMap { doc in
            let d = doc.data()
            guard
                let name    = d["name"]    as? String,
                let address = d["address"] as? String
            else { return nil }
            return SignUpShop(id: doc.documentID, name: name, address: address)
        }
    }
}

// MARK: - DemoOwnerFetcher

/// Stub for previews and unit tests.
public struct DemoOwnerFetcher: OwnerFetching {
    public init() {}

    public func fetchOwners() async throws -> [SignUpOwner] {
        try await Task.sleep(nanoseconds: 600_000_000)
        return SignUpUiState.mockOwners
    }

    public func searchOwners(query: String, limit: Int = 20) async throws -> [SignUpOwner] {
        try await Task.sleep(nanoseconds: 350_000_000)
        let q = query.lowercased()
        return SignUpUiState.mockOwners
            .compactMap { owner -> SignUpOwner? in
                // Match by owner name OR any shop name
                let ownerMatch = owner.name.lowercased().localizedCaseInsensitiveContains(q)
                let shopMatch = owner.shops.contains {
                    $0.name.lowercased().localizedCaseInsensitiveContains(q)
                }
                if ownerMatch || shopMatch {
                    return owner
                }
                return nil
            }
            .prefix(limit)
            .map { $0 }
    }
}
