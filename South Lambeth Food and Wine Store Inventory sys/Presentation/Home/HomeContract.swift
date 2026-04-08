//
//  HomeContract.swift
//  South Lambeth Food and Wine Store Inventory sys
//
//  Created by Mariyan Anjelo on 18/01/2026.
//
import Foundation

public struct HomeState: Equatable {
    public var selectedTab: AppNavTab = .home
    public init() {}
}

public enum HomeEvent: Equatable {
    case onSignOutTapped
    case tabChanged(AppNavTab)
    case scanTapped
}

public enum HomeEffect: Equatable {
    case navigateWelcome
    case openScanner
}
