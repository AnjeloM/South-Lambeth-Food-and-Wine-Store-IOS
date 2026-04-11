import Foundation
import FirebaseFunctions

// MARK: - PasswordResetSending

public protocol PasswordResetSending {
    /// Calls `requestPasswordResetLink`. Always succeeds from the client's perspective
    /// regardless of whether the email exists (backend returns neutral response).
    func sendResetLink(to email: String) async throws
}

public struct FirebasePasswordResetSender: PasswordResetSending {
    public init() {}

    public func sendResetLink(to email: String) async throws {
        let functions = Functions.functions(region: "europe-north1")
        let callable = functions.httpsCallable("requestPasswordResetLink")
        _ = try await callable.call(["email": email])
    }
}

public struct DemoPasswordResetSender: PasswordResetSending {
    public init() {}

    public func sendResetLink(to email: String) async throws {
        try await Task.sleep(nanoseconds: 600_000_000)
    }
}

// MARK: - PasswordResetting

public protocol PasswordResetting {
    /// Calls `resetPasswordWithToken`. Throws a descriptive error on invalid/expired/used token.
    func resetPassword(token: String, newPassword: String) async throws
}

public struct FirebasePasswordResetter: PasswordResetting {
    public init() {}

    public func resetPassword(token: String, newPassword: String) async throws {
        let functions = Functions.functions(region: "europe-north1")
        let callable = functions.httpsCallable("resetPasswordWithToken")
        let result = try await callable.call(["token": token, "newPassword": newPassword])

        guard
            let data = result.data as? [String: Any],
            let ok = data["ok"] as? Bool,
            ok
        else {
            let reason = (result.data as? [String: Any])?["reason"] as? String
            let message: String
            switch reason {
            case "expired": message = "Reset link has expired. Please request a new one."
            case "used":    message = "This reset link has already been used."
            default:        message = "Invalid reset link. Please request a new one."
            }
            throw NSError(
                domain: "FirebasePasswordResetter",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: message]
            )
        }
    }
}

public struct DemoPasswordResetter: PasswordResetting {
    public init() {}

    public func resetPassword(token: String, newPassword: String) async throws {
        try await Task.sleep(nanoseconds: 600_000_000)
    }
}

