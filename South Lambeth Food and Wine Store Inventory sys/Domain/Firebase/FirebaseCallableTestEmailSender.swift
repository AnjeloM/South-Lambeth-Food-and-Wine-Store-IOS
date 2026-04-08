//
//  FirebaseCallableTestEmailSender.swift
//  South Lambeth Food and Wine Store Inventory sys
//

import Foundation

public struct FirebaseCallableTestEmailSender: TestEmailSending {

    private static let endpoint = URL(
        string: "https://europe-north1-inventory-app-352dc.cloudfunctions.net/sendTestEmail"
    )!

    private let testEmail: String

    public init(testEmail: String = "anjelom.1990@gmail.com") {
        self.testEmail = testEmail
    }

    public func sendTestEmail() async throws {
        var request = URLRequest(url: Self.endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(
            withJSONObject: ["data": ["email": testEmail]]
        )

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse else {
            throw CallableError.invalidResponse
        }

        guard (200...299).contains(http.statusCode) else {
            let body = String(data: data, encoding: .utf8) ?? "(no body)"
            throw CallableError.httpError(http.statusCode, body)
        }
    }

    private enum CallableError: LocalizedError {
        case invalidResponse
        case httpError(Int, String)

        var errorDescription: String? {
            switch self {
            case .invalidResponse:       return "Invalid response from server."
            case .httpError(let code, let body): return "Server error \(code): \(body)"
            }
        }
    }
}
