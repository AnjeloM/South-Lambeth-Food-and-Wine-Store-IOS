//
//  AppRoute.swift
//  South Lambeth Food and Wine Store Inventory sys
//
//  Created by Mariyan Anjelo on 18/01/2026.
//
import Foundation

public enum AppRoute: Hashable {
    case gate
    case welcome
    case login
    case resetmail
    /// Intermediate screen: choose "Sign Up as User" or "Sign Up as Owner"
    case roleSelection
    case signup
    /// Owner onboarding — frontend-only until backend is wired
    case ownerSignUp
    // name + password are held in memory only — never written to disk.
    // Cleared automatically when the route changes away from .otp.
    case otp(email: String, name: String, password: String)
    // Arrived via deep link: inventorysys://reset?token=...
    case resetPassword(token: String)
    case home
}
