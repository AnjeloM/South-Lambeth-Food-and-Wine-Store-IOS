import Foundation

public struct SignUpUiState: Equatable {
    // Title
    public var title: String = "SignUp"

    // Inputs
    public var name: String = ""
    public var email: String = ""
    public var password: String = ""
    public var retypePassword: String = ""

    // UI Toggles
    public var isPasswordVisible: Bool = false
    public var isRetypePasswordVisible: Bool = false

    // Labels
    public var nameLabel: String = "Name"
    public var emailLabel: String = "Email"
    public var passwordLabel: String = "Password"
    public var retypePasswordLabel: String = "Retype Password"

    // Password rules (static UI for now)
    public var passwordRules: [String] = [
        "At least 8 characters (required for your password)",
        "Must contain at least 2 lowercase and 2 uppercase letters.",
        "Must contain at least 1 number.",
        "Inclusion of at least one special character, e.g !, @, #, ?, )"
    ]

    // Sign Up button
    public var signUpButtonText: String = "Sign Up"
    public var isLoading: Bool = false

    // Inline error shown below the email field
    public var emailError: String? = nil

    // Social buttons
    public var googleButtonText: String = "Continue with Google"
    public var appleButtonText: String = "Continue with Apple"

    // Footer
    public var footerPrefixText: String = "By continuing forward, you agree to"
    public var footerBrandText: String = "NISHAN INVENTORY"
    public var privacyPolicyText: String = "Privacy Policy"
    public var andText: String = "and"
    public var termsText: String = "Terms & Conditions"

    public init() {}
}
