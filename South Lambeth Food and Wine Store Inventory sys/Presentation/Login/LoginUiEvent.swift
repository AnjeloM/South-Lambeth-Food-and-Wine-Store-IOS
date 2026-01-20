//
//  SignInUiEvent.swift
//  South Lambeth Food and Wine Store Inventory sys
//
//  Created by Mariyan Anjelo on 20/01/2026.
//
import Foundation

public enum LoginEvent: Equatable {
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
}
