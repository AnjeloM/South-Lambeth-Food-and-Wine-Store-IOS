import Foundation

public struct EmailOtpVerificationUiState: Equatable {
    public var title: String = "OTP Verification"
    public var email: String = "anjelom.1990@gmail.com"
    
    // 4 digits
    public var otpDigits: [String] = ["","","",""]
    
    // Verify
    public var isVerifying: Bool = false
    
    // Resend cooldown
    public var resendStepIndex: Int = 0
    public var resendRemainingSeconds: Int = 0
    public var canResend: Bool = false
    
    // Derived
    public var isOtpComplete: Bool = false
    public var verifyEnabled: Bool = false
    public var resendLabel: String = "Resend in: 00:00s"
    
    public init(email: String) {
        self.email = email
    }
}
