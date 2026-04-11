import Foundation
import FirebaseFunctions

/// Production implementation of `EmailOtpServicing`.
/// Calls the `verifyEmailOtp` and `sendEmailOtp` Firebase Cloud Functions.
public struct FirebaseEmailOtpService: EmailOtpServicing {
    public init() {}

    // MARK: - Verify

    public func verifyOtp(email: String, otp: String) async throws {
        let functions = Functions.functions(region: "europe-north1")
        let callable = functions.httpsCallable("verifyEmailOtp")
        let result = try await callable.call(["email": email, "otp": otp])

        guard
            let data = result.data as? [String: Any],
            let valid = data["valid"] as? Bool,
            valid
        else {
            let reason = (result.data as? [String: Any])?["reason"] as? String
            let message = reason == "expired"
                ? "OTP has expired. Please request a new one."
                : "Invalid OTP. Please try again."
            throw NSError(
                domain: "FirebaseEmailOtpService",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: message]
            )
        }
    }

    // MARK: - Resend

    public func resendOtp(email: String) async throws {
        let functions = Functions.functions(region: "europe-north1")
        let callable = functions.httpsCallable("sendEmailOtp")
        _ = try await callable.call(["email": email, "ttlSeconds": 300])
    }
}

