import Foundation

public enum LoginUiEffect: Equatable {
    case navigateBack
    case navigateForgotPassword
    case navigateSignUp
    case navigateHome
    
    case showToast(String)
}
