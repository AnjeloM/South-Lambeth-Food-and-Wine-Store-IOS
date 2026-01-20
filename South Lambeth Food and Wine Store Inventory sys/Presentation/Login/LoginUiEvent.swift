import Foundation

public enum LoginUiEvent: Equatable {
    case onAppear
    
    // Top Bar
    case backTapped
    
    // Inputs
    case emailChanged(String)
    case passwordChanged(String)
    case passwordVisibilityTapped
    
    // Action
    case forgotPasswordTapped
    case loginTapped
    case signUpTapped
    case navigateForgotPassword
}
