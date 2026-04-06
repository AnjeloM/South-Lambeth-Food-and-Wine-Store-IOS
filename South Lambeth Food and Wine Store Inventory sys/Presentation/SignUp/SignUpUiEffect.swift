import Foundation

public enum SignUpUiEffect: Equatable {
    case navigateBack
    case navigateToOtp(String) 
    
    // ON_OFF action (host handles these)
    case continueWithGoogle
    case continueWithApple
    
    case openURL(URL)
    case showToast(String) // optinal placeholder
}
