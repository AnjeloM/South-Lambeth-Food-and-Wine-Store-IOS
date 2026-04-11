import FirebaseFunctions

// MARK: - OwnerShopPayload
//
// Mirrors OwnerShopEntry for the Cloud Function call.
// Kept separate so the Domain layer has no import dependency on Presentation.

public struct OwnerShopPayload {
    public let shopId: String       // UUID string — used as the Firestore document ID
    public let name: String
    public let address: String
    public let phone: String
    public let locationLabel: String
    public let latitude: Double?
    public let longitude: Double?

    public init(
        shopId: String,
        name: String,
        address: String,
        phone: String = "",
        locationLabel: String = "",
        latitude: Double? = nil,
        longitude: Double? = nil
    ) {
        self.shopId        = shopId
        self.name          = name
        self.address       = address
        self.phone         = phone
        self.locationLabel = locationLabel
        self.latitude      = latitude
        self.longitude     = longitude
    }

    /// Serialises to the dict format expected by the `registerOwner` Cloud Function.
    var callPayload: [String: Any] {
        var d: [String: Any] = [
            "shopId":        shopId,
            "name":          name,
            "address":       address,
            "phone":         phone,
            "locationLabel": locationLabel,
        ]
        if let lat = latitude  { d["latitude"]  = lat }
        if let lng = longitude { d["longitude"] = lng }
        return d
    }
}

// MARK: - OwnerRegistering

public protocol OwnerRegistering {
    /// Calls the `registerOwner` Cloud Function, which creates a Firebase Auth user,
    /// writes the `users` document, all `shops` documents, and an `employees` record
    /// per shop — all in a single Firestore batch.
    func registerOwner(
        name: String,
        email: String,
        password: String,
        shops: [OwnerShopPayload],
        defaultShopId: String
    ) async throws
}

// MARK: - FirebaseOwnerRegistrar

/// Production implementation — calls the `registerOwner` Firebase callable function.
public struct FirebaseOwnerRegistrar: OwnerRegistering {
    public init() {}

    public func registerOwner(
        name: String,
        email: String,
        password: String,
        shops: [OwnerShopPayload],
        defaultShopId: String
    ) async throws {
        let functions = Functions.functions(region: "europe-north1")
        let callable  = functions.httpsCallable("registerOwner")

        let payload: [String: Any] = [
            "name":          name,
            "email":         email,
            "password":      password,
            "defaultShopId": defaultShopId,
            "shops":         shops.map { $0.callPayload },
        ]
        _ = try await callable.call(payload)
    }
}

// MARK: - DemoOwnerRegistrar

/// Stub for previews and unit tests — simulates 800 ms latency, always succeeds.
public struct DemoOwnerRegistrar: OwnerRegistering {
    public init() {}

    public func registerOwner(
        name: String,
        email: String,
        password: String,
        shops: [OwnerShopPayload],
        defaultShopId: String
    ) async throws {
        try await Task.sleep(nanoseconds: 800_000_000)
    }
}
