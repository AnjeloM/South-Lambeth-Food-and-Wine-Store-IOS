import Foundation

public struct ResetPasswordUiState: Equatable {
    public var title: String = "Set New Password"

    // Token received from deep link (never shown to user)
    public var token: String

    // Inputs
    public var newPassword: String = ""
    public var confirmPassword: String = ""
    public var isPasswordVisible: Bool = false
    public var isConfirmPasswordVisible: Bool = false

    // Labels
    public var newPasswordLabel: String = "New Password"
    public var confirmPasswordLabel: String = "Confirm Password"

    // UI flags
    public var isLoading: Bool = false
    public var isSubmitEnabled: Bool = false

    // Inline error
    public var errorMessage: String? = nil

    public init(token: String) {
        self.token = token
    }
}
