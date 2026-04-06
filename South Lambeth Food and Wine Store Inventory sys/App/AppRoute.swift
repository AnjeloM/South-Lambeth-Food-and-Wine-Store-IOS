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
    case signup
    case otp(email: String)
    case home

}
