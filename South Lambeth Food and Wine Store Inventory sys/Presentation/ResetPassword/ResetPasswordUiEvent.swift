import Foundation

public enum ResetPasswordUiEvent: Equatable {
    case onAppear
    case newPasswordChanged(String)
    case confirmPasswordChanged(String)
    case toggleNewPasswordVisibility
    case toggleConfirmPasswordVisibility
    case submitTapped
}
