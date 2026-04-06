import Foundation

public protocol EmailOtpServicing {
    func verifyOtp(email: String, otp: String) async throws
    func resendOtp(email: String) async throws
}
