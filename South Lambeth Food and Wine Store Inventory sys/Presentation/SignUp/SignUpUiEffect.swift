import Foundation

public enum SignUpUiEffect: Equatable {
    case navigateBack
    case navigateToOtp(email: String, name: String, password: String)
    
    // ON_OFF action (host handles these)
    case continueWithGoogle
    case continueWithApple
    
    case openURL(URL)
    case showToast(String) // optinal placeholder
}
