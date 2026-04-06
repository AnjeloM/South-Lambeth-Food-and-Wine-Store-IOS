import SwiftUI

fileprivate struct PreviewEmailOtpService: EmailOtpServicing {
    let expectedOtp: String

    func verifyOtp(email: String, otp: String) async throws {
        try await Task.sleep(nanoseconds: 300_000_000)
        if otp != expectedOtp {
            throw NSError(domain: "OTP", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid OTP"])
        }
    }

    func resendOtp(email: String) async throws {
        try await Task.sleep(nanoseconds: 250_000_000)
    }
}

#Preview("OTP - Dark") {
    EmailOtpVerificationRouteHostView(
        email: "anjelom.90@gmail.com",
        service: PreviewEmailOtpService(expectedOtp: "1234"),
        onBack: {},
        onVerified: {},
        onToast: { _ in }
    )
    .preferredColorScheme(.dark)
}

#Preview("OTP - Light") {
    EmailOtpVerificationRouteHostView(
        email: "anjelom.90@gmail.com",
        service: PreviewEmailOtpService(expectedOtp: "1234"),
        onBack: {},
        onVerified: {},
        onToast: { _ in }
    )
    .preferredColorScheme(.light)
}

