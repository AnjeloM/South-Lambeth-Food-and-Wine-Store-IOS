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
    case ownerSignUp
    // name + password are held in memory only — never written to disk.
    // Cleared automatically when the route changes away from .otp.
    case otp(email: String, name: String, password: String)
    /// Owner OTP verification — carries in-memory credentials + shop list.
    /// Cleared automatically when the route changes away from .ownerOtp.
    case ownerOtp(
        email: String,
        name: String,
        password: String,
        shops: [OwnerShopEntry],
        defaultShopId: UUID
    )
    // Arrived via deep link: inventorysys://reset?token=...
    case resetPassword(token: String)
    /// User is authenticated but has no shop assignment — must request to join a shop before Home.
    case joinShop
    case home
}
