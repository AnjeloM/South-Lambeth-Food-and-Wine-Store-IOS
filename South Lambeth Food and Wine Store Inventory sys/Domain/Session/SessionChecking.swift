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

/// Extends SessionChecking with write operations to persist sign-in state.
/// AppRootView owns the SessionManaging instance and calls save/clear at
/// navigation boundaries (login success, OTP verified, sign-out).
public protocol SessionManaging: SessionChecking {
    func saveSession()
    func clearSession()
}

// MARK: Firebase – pending
/// Persists sign-in state in UserDefaults (non-sensitive boolean flag only).
/// When Firebase is wired, replace with a FirebaseSessionManager that reads
/// the Firebase Auth current user instead.
public final class LocalSessionManager: SessionManaging {
    private let key = "app.isSignedIn"

    public init() {}

    public func isSignedIn() async -> Bool {
        UserDefaults.standard.bool(forKey: key)
    }

    public func saveSession() {
        UserDefaults.standard.set(true, forKey: key)
    }

    public func clearSession() {
        UserDefaults.standard.set(false, forKey: key)
    }
}

// MARK: - Demo stub (previews and tests only)
public struct DemoSessionChecker: SessionChecking {
    public let signedIn: Bool
    public init(signedIn: Bool) { self.signedIn = signedIn }
    public func isSignedIn() async -> Bool { signedIn }
}
