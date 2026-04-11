//
//  SignUpDependencies.swift
//  South Lambeth Food and Wine Store Inventory sys
//

import FirebaseFunctions

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
