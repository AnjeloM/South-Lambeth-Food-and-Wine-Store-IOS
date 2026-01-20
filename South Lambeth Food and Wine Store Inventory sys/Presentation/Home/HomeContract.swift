//
//  HomeContract.swift
//  South Lambeth Food and Wine Store Inventory sys
//
//  Created by Mariyan Anjelo on 18/01/2026.
//
import Foundation

public struct HomeState: Equatable {
    public var title: String = "Home"
    public var subTitle: String = "You are signed in"
    public var signOutButtonText: String = "SIGN OUT (GO WELCOME)"
    public init() {}
}

public enum HomeEvent: Equatable {
    case onSignOutTapped
}

public enum HomeEffect: Equatable {
    case navigateWelcome
}
