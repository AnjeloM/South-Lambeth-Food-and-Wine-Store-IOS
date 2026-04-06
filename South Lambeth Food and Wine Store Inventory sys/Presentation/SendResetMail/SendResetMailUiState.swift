import Foundation

public struct SendResetMailUiState: Equatable {
    // Title
    public var title: String = "Reset Password"
    
    // Inoputs
    public var email: String = ""
    
    // UI flags
    public var isSubmitting: Bool = false
    public var isResendEnabled: Bool = false
    
    // Labels
    public var emailLabel:String = "Email"
    
    // Cooldown
    public var cooldownSecondsRemaining: Int? = nil
    public var cooldownLevelIndex: Int = 0 // 0..4
    public var cooldownText: String? = nil // "00:52
    
    public init () {}
}
