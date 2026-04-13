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
    /// Live user profile shown in the drawer — loaded from Firestore on VM init.
    public var drawerProfile: DrawerProfile?
    /// Latest unread owner notification that should light the bell badge and deep-link into Manage Shop.
    public var unreadNotification: OwnerRequestNotification?
    public init() {}
}

public enum HomeEvent: Equatable {
    case onAppear
    case onSignOutTapped
    case tabChanged(AppNavTab)
    case scanTapped
    case openSetPrintOrder
    case onSetPrintOrderClosed
    case openManageShop
    case notificationTapped
    case onManageShopClosed
}

public enum HomeEffect: Equatable {
    case navigateWelcome
    case openScanner
    case openSetPrintOrder
    case openManageShop(highlightRequestID: String?)
}
