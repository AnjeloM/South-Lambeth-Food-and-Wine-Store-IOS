//
//  SignInUiState.swift
//  South Lambeth Food and Wine Store Inventory sys
//
//  Created by Mariyan Anjelo on 19/01/2026.
//
import Foundation

public struct LoginState: Equatable {
    // Screen title
    public var title: String = "Login"

    // Inputs
    public var email: String = ""
    public var password: String = ""
    public var isPasswordVisible: Bool = false

    // UI enable/disable (computed by ViewModel, not by the view)
    public var isLoginEnabled: Bool = false

    // Labels / static text
    public var emailLabel: String = "Email"
    public var passwordLabel: String = "Password"
    public var forgotPasswordText: String = "Forgot Password?"
    public var loginButtonText: String = "Login"
    public var signUpLinkPrefixText: String = "Don't have an account?"
    public var signUpLinkButtonText: String = "SignUp"

    // Message placeholder
    public var inlineMessage: String? = nil

    public init() {}
}
