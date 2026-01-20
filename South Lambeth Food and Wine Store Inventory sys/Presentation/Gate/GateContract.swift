//
//  GateContract.swift
//  South Lambeth Food and Wine Store Inventory sys
//
//  Created by Mariyan Anjelo on 17/01/2026.
//
import Foundation

public struct GateState: Equatable {
    public var titleTop: String = "SOUTH LAMBETH"
    public var titleMiddle: String = "Food & Wine"
    public var titlteStore: String = "STORE"
    public var subtitile: String = "Inventory System"
    public var isLoading: Bool = false
    
    public init() {}
}

public enum GateEvent: Equatable {
    case onAppear
    case routeResolved(GateRoute)
}

public enum GateEffect: Equatable {
    case navigate(GateRoute)
}

public enum GateRoute: Equatable {
    case welcome
    case home
}
