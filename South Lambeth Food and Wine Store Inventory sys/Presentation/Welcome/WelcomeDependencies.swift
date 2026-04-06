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
public struct DemoEmailOtpService: EmailOtpServicing {
    public init() {}
    public func verifyOtp(email: String, otp: String) async throws {
        // Simulate a short delay and accept a fixed demo OTP
        try await Task.sleep(nanoseconds: 400_000_000)
        guard otp == "123456" else {
            throw NSError(domain: "DemoEmailOtpService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid OTP"])
        }
    }

    public func resendOtp(email: String) async throws {
        // Simulate a short delay for resending
        try await Task.sleep(nanoseconds: 300_000_000)
        // No-op success
    }
}

