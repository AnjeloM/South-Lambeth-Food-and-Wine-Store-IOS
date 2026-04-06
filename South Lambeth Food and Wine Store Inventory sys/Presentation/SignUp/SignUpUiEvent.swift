import Foundation

public enum SignUpUiEvent: Equatable {
    case onAppear
    case onbackTapped
    
    // Input cases
    case nameChanged(String)
    case emailChanged(String)
    case passwordChanged(String)
    case retypePasswordChanged(String)
    
    // Toggles
    case togglePasswordVisibility
    case toggleRetypePasswordVisibility
    
    // Social actions
    case googleTapped
    case appleTapped
    
    // Footer links
    case privacyPolicyTapped
    case termsTapped
    
}

