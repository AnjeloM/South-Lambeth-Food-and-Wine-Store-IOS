//
//  FirebaseUserRegistrar.swift
//  South Lambeth Food and Wine Store Inventory sys
//

import FirebaseFunctions

// MARK: - UserRegistering

public protocol UserRegistering {
    /// Calls the `registerUser` Cloud Function, which creates a Firebase Auth user
    /// and writes the corresponding document to the `users` Firestore collection.
    func register(email: String, name: String, password: String) async throws
}

// MARK: - FirebaseUserRegistrar

/// Production implementation — calls the `registerUser` Firebase callable function.
public struct FirebaseUserRegistrar: UserRegistering {
    public init() {}

    public func register(email: String, name: String, password: String) async throws {
        let functions = Functions.functions(region: "europe-north1")
        let callable = functions.httpsCallable("registerUser")
        _ = try await callable.call(["email": email, "name": name, "password": password])
    }
}

// MARK: - DemoUserRegistrar

/// Stub for previews and unit tests — simulates 600 ms latency, always succeeds.
public struct DemoUserRegistrar: UserRegistering {
    public init() {}

    public func register(email: String, name: String, password: String) async throws {
        try await Task.sleep(nanoseconds: 600_000_000)
    }
}
