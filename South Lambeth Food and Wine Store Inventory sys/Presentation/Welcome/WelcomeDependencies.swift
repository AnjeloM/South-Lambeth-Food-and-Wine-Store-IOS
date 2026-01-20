//
//  WelcomeDependencies.swift
//  South Lambeth Food and Wine Store Inventory sys
//
//  Created by Mariyan Anjelo on 19/01/2026.
//
import Foundation

public protocol TestEmailSending {
    func sendTestEmail() async throws
}

public struct DemoTestEmailSender: TestEmailSending {
    public init() {}
    public func sendTestEmail() async throws {
        try await Task.sleep(nanoseconds: 600_000_000)  // simulate latency for now
        // success
    }
}
