//
//  HomeContract.swift
//  South Lambeth Food and Wine Store Inventory sys
//
//  Created by Mariyan Anjelo on 18/01/2026.
//
import Foundation

public struct HomeState: Equatable {
    public var selectedTab: AppNavTab = .home
    /// The current default print list — loaded on VM init, refreshed after SetPrintOrder is closed.
    public var defaultPrintList: PrintOrderList?
    public init() {}
}

public enum HomeEvent: Equatable {
    case onSignOutTapped
    case tabChanged(AppNavTab)
    case scanTapped
    case openSetPrintOrder
    case onSetPrintOrderClosed
}

public enum HomeEffect: Equatable {
    case navigateWelcome
    case openScanner
    case openSetPrintOrder
}
