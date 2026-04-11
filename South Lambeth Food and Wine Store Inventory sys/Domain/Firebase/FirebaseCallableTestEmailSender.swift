//
//  FirebaseCallableTestEmailSender.swift
//  South Lambeth Food and Wine Store Inventory sys
//

import FirebaseFunctions

// MARK: - FirebaseCallableTestEmailSender
// Calls the `sendTestEmail` Firebase callable function (v2) via the Firebase Functions SDK.
// SES sandbox: only anjelom.1990@gmail.com (verified identity) is accepted as recipient.

public struct FirebaseCallableTestEmailSender: TestEmailSending {

    private let testEmail: String

    public init(testEmail: String = "anjelom.1990@gmail.com") {
        self.testEmail = testEmail
    }

    // MARK: - TestEmailSending

    public func sendTestEmail() async throws {
        let functions = Functions.functions(region: "europe-north1")
        let callable = functions.httpsCallable("sendTestEmail")
        _ = try await callable.call(["email": testEmail])
    }
}
