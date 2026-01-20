//
//  SessionChecking.swift
//  South Lambeth Food and Wine Store Inventory sys
//
//  Created by Mariyan Anjelo on 17/01/2026.
//
import Foundation

public protocol SessionChecking {
    func isSignedIn() async -> Bool
}

// Temproary stub so the runs before wire firebase
public struct DemoSessionChecker: SessionChecking {
    public let signedIn: Bool
    public init(signedIn: Bool) {self.signedIn = signedIn}
    public func isSignedIn() async -> Bool {signedIn}
}
